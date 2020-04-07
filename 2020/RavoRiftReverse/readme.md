# Super Ravo Zapper reverse engineering

![Super ravo zapper](image.jpg)

Ravo Rive application is supplied with Super Ravo Zapper device, you can find more information here:
- Device: [https://www.pro-zdravi.net/produkt/super-ravo-zapper](https://www.pro-zdravi.net/produkt/super-ravo-zapper)
- Application download location: [https://www.super-ravo-zapper.cz/ke-stazeni-download](https://www.super-ravo-zapper.cz/ke-stazeni-download)

Installation package was built using InnoSetup packager, it can be unpacked using innoextract utility:

    brew install innoextract
    innoextract Rife_setup_1_21.exe
    
After extracting you will find some FTDI driver packages, encrypted dataases, java libraries and main application file in form of JAR archive. It is a simple GUI based java app (RAVO_RIFE.JAR) which allows uploading various presets into the Super Ravo Zapper device. To disassemble whole application I have used jadx decompiler

    brew install jadx
    jadx RAVO_RIFE.jar
    
Right in the *Main.java* we can see references to the encrypted files (cafl/cafl_eng.txt) and the encryption/decryption algorithm placed in ravo_rife.EncDec class:

```
import javax.crypto.SecretKey;
import ravo_rife.EncDec;
import ravo_rife.loggers.IRifeLogger;
import ravo_rife.loggers.RifeLogger;

public class Main {
    private static final String[] CHYBY = {"Očekává se číslo", "Očekává se číslo, nebo des. tečka"};
    private static final String CISLA = "0123456789";
    private static final int STATE_CHYBA = 100;
    private static final int STATE_CISLO_PRED_DT = 6;
    private static final int STATE_CISLO_ZA_DT = 7;
    private static final int STATE_DALSI_CISLO = 5;
    private static final int STATE_NAZEV = 1;
    private static final int STATE_NM = 2;
    private static final int STATE_NMP = 3;
    private static final int STATE_NMPM = 4;
    private static final int STATE_PK = 9;
    private static final int STATE_PKM = 10;
    private static final int STATE_PKMP = 11;
    private static final int STATE_PKMPM = 12;
    private static final int STATE_POPIS = 8;

    public static void main(String[] args) {
        exportPatogens(parsePatogenFile("C:\\RAVO\\DOC\\CAFL\\CAFL_ENG.txt"), "C:\\RAVO\\DOC\\CAFL\\CAFL_ENG.csv", "C:\\RAVO\\DOC\\CAFL\\CAFL_ENG.ptg", new RifeLogger());
    }

    public static void exportPatogens(List<PatogenInfo> patogens, String fileNameCSV, String fileNamePTG, IRifeLogger logger) {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        SecretKey key = EncDec.getKey(logger, "AGyy4_kl66!ye4@.35");
        File f = new File(fileNameCSV);
        File e = new File(fileNamePTG);
        try {
            FileOutputStream fileOutputStream = new FileOutputStream(f);
            BufferedWriter bw = new BufferedWriter(new OutputStreamWriter(fileOutputStream));
            FileOutputStream fileOutputStream2 = new FileOutputStream(e);
            BufferedOutputStream bos = new BufferedOutputStream(fileOutputStream2);
            for (PatogenInfo patogen : patogens) {
                List<String> frequenciesForExport = patogen.getFrequenciesExportList();
                if (frequenciesForExport.size() > 0) {
                    for (String frequency : frequenciesForExport) {
                        String record = String.format("%s;%s;%s;%s\n", new Object[]{patogen.getShortName(), patogen.getLongNameForExport(), patogen.getDescriptionForExport(), frequency});
                        bw.write(record);
                        byte[] bytes = record.getBytes();
                        baos.write(bytes, 0, bytes.length);
                    }
                } else {
                    System.out.println("Bez frekvenci: " + patogen.getLongName());
                    String record2 = String.format("%s;%s;%s;;;;;;;\n", new Object[]{patogen.getShortName(), patogen.getLongNameForExport(), patogen.getDescriptionForExport()});
                    bw.write(record2);
                    byte[] bytes2 = record2.getBytes();
                    baos.write(bytes2, 0, bytes2.length);
                }
            }
            byte[] encryptedData = EncDec.encryptData(baos.toByteArray(), key, logger, "AGyy4_kl66!ye4@.35");
            bos.write(encryptedData, 0, encryptedData.length);
            bos.flush();
            bos.close();
            bw.flush();
            bw.close();
        } catch (IOException ex) {
            System.out.println(ex);
        }
    }
//...
```

The supplied key "AGyy4_kl66!ye4@.35" is not a real decryption key, it just some unusal mechanism to unlock the EncDec class. After analysing [this class](EncDec.java), we can see the real encryption algorithm "DESede/CBC/PKCS5Padding" as well as the decryption key "ort_8jiosbjihog135687984"

By creating simple java app which just calls the decryption methods from EncDec class we can quickly decrypt the database:

```
class main {  
  public static void main(String args[]){  
    EncDec edec = new EncDec();
    edec.decodeFile("CAFL_CZ.ptg", "out_cz.txt", "AGyy4_kl66!ye4@.35");
  }  
} 
```

To run, just call:
    
    javac EncDec.java
    java main.java
    
    
And voila, you have the cure for coronavirus:

> CORONAVIRUS SARS;Coronavirus. SARS;;;9918;0;3;0;0;kHz\
> CORONAVIRUS SARS;Coronavirus. SARS;;;9740;0;3;0;0;kHz\
> CORONAVIRUS SARS;Coronavirus. SARS;;;4959;0;3;0;0;kHz\
> CORONAVIRUS SARS;Coronavirus. SARS;;;4870;0;3;0;0;kHz\
> CORONAVIRUS SARS;Coronavirus. SARS;;2479;2480;1;3;0;0;kHz\
> CORONAVIRUS SARS;Coronavirus. SARS;;;2435;0;3;0;0;kHz\
> CORONAVIRUS SARS;Coronavirus. SARS;;1394;1395;1;3;0;0;kHz\
> CORONAVIRUS SARS;Coronavirus. SARS;;1369;1370;1;3;0;0;kHz\
> CORONAVIRUS SARS;Coronavirus. SARS;;1239;1240;1;3;0;0;kHz\
> CORONAVIRUS SARS;Coronavirus. SARS;;1217;1218;1;3;0;0;kHz\
> CORONAVIRUS SARS;Coronavirus. SARS;;;774800;0;3;0;0;Hz\
> CORONAVIRUS SARS;Coronavirus. SARS;;;760900;0;3;0;0;Hz\
> CORONAVIRUS SARS;Coronavirus. SARS;;;619900;0;3;0;0;Hz\
> CORONAVIRUS SARS;Coronavirus. SARS;;;608700;0;3;0;0;Hz\
> CORONAVIRUS SARS;Coronavirus. SARS;;;464900;0;3;0;0;Hz\
> CORONAVIRUS SARS;Coronavirus. SARS;;;456500;0;3;0;0;Hz\
> CORONAVIRUS SARS;Coronavirus. SARS;;;309900;0;3;0;0;Hz\
> CORONAVIRUS SARS;Coronavirus. SARS;;;304400;0;3;0;0;Hz\
> CORONAVIRUS SARS;Coronavirus. SARS;;;155000;0;3;0;0;Hz\
> CORONAVIRUS SARS;Coronavirus. SARS;;;152200;0;3;0;0;Hz

The values matches the PatogenData class with following constructor (just the hzKhz boolean is at the end)
```
    public PatogenData(String shortName2, String longName2, String description2, boolean constantFreq2, Long freqFrom2, Long freqTo2, Long shiftSpeed2, boolean hzKhz2, Integer lenHours2, Integer lenMinutes2, Integer lenSeconds2)
```

So following line *CORONAVIRUS SARS;Coronavirus. SARS;;;304400;0;3;0;0;Hz* can be translated: shortName=CORONAVIRUS SARS, longName=Coronavirus. SARS, constatFreq=none, freqFrom=none, freqTo=304.4kHz, shiftSpeed=0, hzKhz=3?, lenHours=0, lenMinutes=0, lenSeconds=3. In human language, it will configure the generator to produce 304.4 kHz for 3 seconds and then jump to the next line in database

## Hardware reverse engineering

After analysing the output signal with oscilloscope, I have found out following:
- During startup, the amplitude slowly rises to 15V, when there is no impedance at the output, the device will beep and notify the user that something is wrong. The human holding two stainless steel electrodes can be faked by attaching 680 ohm resistor to the output
- The device just produces square signal with 50% duty cycle with slightly altering frequency
- Frequency alternations should match the table in encrypted database. Multiple frequencies (lines) with the same patogen name are generated in sequence
- The amplitude of the generator is fixed during use, so the only parameter which varies in time is frequency


## Closing words...

Here is the list of illnessess / parasites and problems the device can "handle"

![List](list.png)

and here is the decrypted database: [cafl_cz.ptg.txt](cafl_cz.ptg.txt)

