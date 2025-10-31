# Das Skript liest in Multiplot gespeicherte Daten wieder ein
# und zeigt sie in Plot-Fenster an
#
dataStream = [];

readData = load("Einzelelektroden.txt");
streamCount = (length(readData.dataMatrix)/3)

disp(streamCount)

for i = 1:streamCount
  dataStream(i).name = readData.dataMatrix{(i-1)*3+1};
  dataStream(i).array = readData.dataMatrix{(i-1)*3+2};
  dataStream(i).t     = readData.dataMatrix{(i-1)*3+3};
endfor

subplot(3,1,1)
plot(dataStream(1).array);
subplot(3,1,2)
plot(dataStream(2).array);

differenz = dataStream(1).array - dataStream(2).array;
subplot(3,1,3)
plot(differenz);









