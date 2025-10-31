classdef plotGraphClass < handle

  properties
    fi_1 = 0;
    fid  = 0;
    subPl = [];
    subLi = [];
  endproperties

  methods
    function self = plotGraphClass(dataStream)    # Constructor
      graphics_toolkit("qt");
      self.fi_1 = figure(1);
      pos = get(self.fi_1,"outerposition");
      #set(self.fi_1,"outerposition", [pos(1),pos(2),1000,1000]);
      #set(self.fi_1,"outerposition", [pos(1),pos(2),300,300]);
      spN = 0;
      for i = 1:length(dataStream);
        if (dataStream(i).plot == 1)
          spN = spN + 1;
        endif
      endfor
      j=0;
      for i = 1:length(dataStream)
        if (dataStream(i).plot == 1)
          j=j+1;
          ## The function subplot returns a handle pointing to an object of type axes.
          self.subPl(j) = subplot(spN,1,j);
          set(self.subPl(j),"box","on","title",dataStream(i).name,"xlim",[0 dataStream(i).plotwidth*5]);
          # wenn ylim Grenzen nutzt
          if (sum(dataStream(j).ylim != 0))
            set(self.subPl(j),"ylim",dataStream(i).ylim);
          endif
          # Zeichenfarbe setzen
          self.subLi(j) = line("linewidth",2,"color",dataStream(i).plcolor);
        endif
      endfor
      pos = get(self.fi_1,"position");
      set(self.fi_1,"position", [pos(1)+1,pos(2)+1,1000,1000]);
      shg();
      refresh(self.fi_1);

      % BPM-Datenaufzeichnung vorbereiten
      timestamp = datestr(now, "yyyymmdd_HHMMSS");
      filename = ["ecg_data_" timestamp ".csv"];
      self.fid = fopen(filename, "a");
    endfunction

    function draw(self,dataStream)
      j=0;  # iteriert ueber die subPlot-Instanzen
      for i = 1:length(dataStream);
        # wenn plot == 1 dann wird das array des dataStream geplottet >> adc_plot
        if (dataStream(i).plot == 1 && dataStream(i).index > 1)
        #if (dataStream(i).plot == 1)
          j=j+1;
          if (dataStream(i).index > dataStream(i).plotwidth) # Fenster scrollt
             # Hier holt dataStream die letzten N-Samples (N=plotwidth)
             [adc_plot, data_t] = dataStream(i).lastSamples(dataStream(i).plotwidth);
             x_axis = [data_t(1) data_t(end)];
           else
             [adc_plot, data_t] = dataStream(i).lastSamples(dataStream(i).ar_index-1);
             x_axis = [data_t(1) data_t(end)];
          endif

          if (ishandle(self.fi_1))
            set(self.subPl(j),"xlim",x_axis);
            set(self.subLi(j),"xdata",data_t,"ydata",adc_plot);
            set(self.subPl(j),"fontsize",20);
            % Es ist eine neue R-Zacke detektiert worden
            if (dataStream(i).newBPM)
              titleText = strcat("BPM:",num2str(dataStream(i).BPM));
              set(self.subPl(j),"title",titleText);
              % Ausgabe der BPM-Werte
              if (dataStream(1).t(dataStream(1).ar_index) > 0)
                bpm_value = dataStream(1).BPM;
                t_value   = dataStream(1).t(dataStream(1).ar_index);
                % In Datei schreiben
                fprintf(self.fid, "%d,%d\n", t_value, bpm_value);
                fflush(self.fid);
                % Daten auf der Konsole anzeigen
                disp([t_value, bpm_value]);
              endif
              % ======================
             dataStream(i).newBPM = 0;
            endif
          endif
        endif # (dataStream(i).plot==1)
      endfor
    endfunction

  endmethods
end
