classdef serialPortClass < handle

  properties
    streamSelector = [];
    regex_pattern = '';
    serialPortPath = '';
    inBuffer = '';
    port_01 = '';
  endproperties

  methods
    function self = serialPortClass(baudrate)    # Constructor
      close self.port_01;
      disp('Searching Serial Port ... ')
      i = 0;
      do
        i = i + 1;
        disp(i)
        self.serialPortPath = self.checkSerialPort(baudrate);
      until (!isempty(self.serialPortPath) || i == 3)
      if (!isempty(self.serialPortPath))
        disp("Serial Port found:")
        disp(self.serialPortPath)
      else
        disp("No Device found!");
      endif
      if (!isempty(self.serialPortPath))
        self.clearPort();
        disp('Receiving data!')
      endif
    endfunction

    function clearPort(self)
      #flush(self.port_01);
      posLF = 0;
      do
        bytesAvailable = self.port_01.NumBytesAvailable;
        if (bytesAvailable > 0)
          inSerialPort = char(read(self.port_01,bytesAvailable));
          posLF        = index(inSerialPort,char(10),"last");
        endif
      until (posLF > 0);
      # erst ab dem letzten \n geht es los
      self.inBuffer = inSerialPort(posLF+1:end);
    endfunction

    function portReturn = checkSerialPort(self,baudrate)
      fehler = false;
      ports = serialportlist();
      portIndex = 1;
      port_found = false;
      portReturn = '';
      while(portIndex <= length(ports) && !port_found)
        #disp(ports{portIndex})
        try
          clear self.port_01;
          disp(ports{portIndex});
          self.port_01 = serialport(ports{portIndex},baudrate);
        catch
          fehler = true;
          disp(lasterror.message);
        end_try_catch
        if (fehler == false)
          #pause(1)
          #flush(port_01);
          pause(2)
          bytesAvailable = self.port_01.NumBytesAvailable;
          if (bytesAvailable > 0)
            inSerialPort = char(read(self.port_01,bytesAvailable));
            firstCRLF    = index(inSerialPort, "\r\n","first");
            lastCRLF     = index(inSerialPort, "\r\n","last");
            if (lastCRLF > firstCRLF)
              inChar   = inSerialPort(firstCRLF:lastCRLF);
              try
                 values   = strsplit(inChar, {':',',','\n','\r'});
              catch
                 disp(lasterror.message);
                 values = {};
              end_try_catch
              data = unique(values);
              filtered_data = {};
              for i = 1:numel(data)
                if !any(isstrprop(data{i}, 'digit'))
                  if !isempty(data{i})
                    filtered_data{end+1} = data{i};
                  endif
                endif
              endfor
              if !isempty(filtered_data)
                msg = [self.port_01.Port ,"\n"];
                for i = 1:length(filtered_data)
                  msg = [msg,filtered_data{i},";"];
                endfor
                portReturn = self.port_01.Port;
                port_found = true;
                disp(msg);
              endif
              #disp(filtered_data)
            endif
          endif                       # bytesAvailable
          # clear port_01;
        else                          # fehler == false
          fehler = false;
        endif
        portIndex = portIndex + 1;
      endwhile
    endfunction

    function [bytesAvailable,inChar] = readPort(self)
      bytesAvailable = 0;
      inChar = '';
      if (self.port_01.NumBytesAvailable > 100)
        buffer_count = 0;
        do
           buffer_count += 1;
           bytesAvailable = self.port_01.NumBytesAvailable;
           inSerialPort   = char(read(self.port_01,bytesAvailable));
           self.inBuffer  = [self.inBuffer inSerialPort];
        until (self.port_01.NumBytesAvailable == 0)
        posLF          = index(self.inBuffer,char(10),"last");
        inChar         = '';
        if (posLF > 0)
          inChar   = self.inBuffer(1:posLF);
          self.inBuffer = self.inBuffer(posLF+1:end);
        endif
      endif
    endfunction

    function countMatches = parseInput(self,inChar,dataStream)
      matches = regexp(inChar, self.regex_pattern, 'tokens');     # Regular Expression auswerten
      countMatches   = length(matches);                           # Wert wird ausgegeben
      if (countMatches == 0)
        disp("RegEx-Error");
        disp(length(inChar));
      endif
      # Code-Optimierung
      # ================
      if countMatches > 0
        # Die Tripels in Matches werden auf die Arrays streamNames, sampleCells, timestampCells verteilt
        [streamNames, sampleCells, timestampCells] = cellfun(@(x) deal(x{1}, x{2}, x{3}),matches,'UniformOutput',false);
        #
        samples = str2double(sampleCells);
        timestamps = str2double(timestampCells);
        #j_indices = cellfun(@(x) self.streamSelector(x),streamNames);
        # Hier werden die Daten für die einzelnen dataStreams vorsortiert.
        # Jeder Datenstrom wird dann nur einmal mit einer Liste aufgerufen.
        % Erzeuge eine Lookup-Tabelle für eindeutige Stream-Namen
        uniqueStreams = unique(streamNames);
        % Gruppiere die Daten nach Streams
        groupedData = struct();
        for i = 1:length(uniqueStreams)
          stream = uniqueStreams{i};
          idx = strcmp(streamNames,stream);
          % Speichere gruppierte Daten in der Struktur
          groupedData.(stream).samples = samples(idx);
          groupedData.(stream).timestamps = timestamps(idx);
        endfor
        % Aufruf für jeden Stream nur einmal
        for k = 1:length(uniqueStreams)
          stream = uniqueStreams{k};
          j = self.streamSelector(stream);
          % Übergabe der gesamten Liste auf einmal an addSample
          dataStream(j).addSamples(groupedData.(stream).samples,groupedData.(stream).timestamps);
        endfor
      endif
    endfunction
    % Die Auswertung erwartet die Daten in der Form:
    % Messsystem:Messwert,t:Zeit_in_Millisekunden (z.B. EKG:128,t:1023040)
    % Pro Messung gibt es eine Zeile
    function createRegEx(self,dataStream)
      self.regex_pattern = '(';
      for i = 1:length(dataStream)
        self.regex_pattern = [self.regex_pattern dataStream(i).name];
        if i < length(dataStream)
          self.regex_pattern = [self.regex_pattern '|'];
        endif
      endfor
      self.regex_pattern = [self.regex_pattern '):(-?\d+),t:(\d+)'];
    endfunction

    function createSelector(self,dataStream)
      # Liste aller dataStream Namen erstellen fuer Dictonary
      namelist = {};
      for i = 1:length(dataStream)
        namelist{end+1} = dataStream(i).name;
      endfor
      values = 1:numel(dataStream);
      self.streamSelector = containers.Map(namelist,values);
    endfunction
  endmethods
end
