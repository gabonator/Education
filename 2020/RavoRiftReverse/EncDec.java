import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.KeyGenerator;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.SecretKey;
import javax.crypto.spec.IvParameterSpec;

public class EncDec {
    private static final String RUN_PASSWORD = "AGyy4_kl66!ye4@.35";

    public static SecretKey getRandomKey(String runPass) {
        SecretKey key = null;
        if (!runPass.equals(RUN_PASSWORD)) {
            SecretKey secretKey = key;
            return null;
        }
        try {
            key = KeyGenerator.getInstance("DESede").generateKey();
        } catch (NoSuchAlgorithmException ex) {
        }
        SecretKey secretKey2 = key;
        return key;
    }

    public static SecretKey getKey(String runPass) {
        if (!runPass.equals(RUN_PASSWORD)) {
            return null;
        }
        return new SecretKey() {
            public String getAlgorithm() {
                return "DESede";
            }

            public String getFormat() {
                return "RAW";
            }

            public byte[] getEncoded() {
                return new String("ort_8jiosbjihog135687984").getBytes();
            }
        };
    }

    public static void encodeFile(String fileName, String runPass) {
        if (runPass.equals(RUN_PASSWORD)) {
            File fileToEncode = new File(fileName);
            try {
                FileInputStream fis = new FileInputStream(fileToEncode);
                BufferedInputStream bis = new BufferedInputStream(fis);
                byte[] content = new byte[new Long(fileToEncode.length()).intValue()];
                bis.read(content);
                byte[] encodedContent = encryptData(content, getKey(RUN_PASSWORD), RUN_PASSWORD);
                bis.close();
                fis.close();
                fileToEncode.delete();
                FileOutputStream fos = new FileOutputStream(new File(fileName));
                BufferedOutputStream bos = new BufferedOutputStream(fos);
                bos.write(encodedContent);
                bos.flush();
                bos.close();
                fos.close();
            } catch (IOException ex) {
            }
        }
    }

    public static void decodeFile(String sourceFileName, String destinationFileName, String runPass) {
        if (runPass.equals(RUN_PASSWORD)) {
            File sourceFile = new File(sourceFileName);
            try {
                FileInputStream fis = new FileInputStream(sourceFile);
                BufferedInputStream bis = new BufferedInputStream(fis);
                byte[] content = new byte[new Long(sourceFile.length()).intValue()];
                bis.read(content);
                byte[] decodedContent = decryptData(content, getKey(RUN_PASSWORD), RUN_PASSWORD);
                bis.close();
                fis.close();
                FileOutputStream fos = new FileOutputStream(new File(destinationFileName));
                BufferedOutputStream bos = new BufferedOutputStream(fos);
                bos.write(decodedContent);
                bos.flush();
                bos.close();
                fos.close();
            } catch (Exception ex) {
            }
        }
    }

    public static byte[] encryptData(byte[] sourceData, SecretKey key, String runPass) {
        if (!runPass.equals(RUN_PASSWORD)) {
            return null;
        }
        boolean z = false;
        try {
            Cipher cipher = Cipher.getInstance("DESede/CBC/PKCS5Padding");
            cipher.init(1, key, new IvParameterSpec(new byte[8]));
            return cipher.doFinal(sourceData);
        } catch (InvalidAlgorithmParameterException ex) {
            return new byte[0];
        } catch (IllegalBlockSizeException ex2) {
            return new byte[0];
        } catch (BadPaddingException ex3) {
            return new byte[0];
        } catch (InvalidKeyException ex4) {
            return new byte[0];
        } catch (NoSuchPaddingException ex5) {
            return new byte[0];
        } catch (NoSuchAlgorithmException ex6) {
            return new byte[0];
        }
    }

    public static byte[] decryptData(byte[] sourceData, SecretKey key, String runPass) throws Exception {
        if (!runPass.equals(RUN_PASSWORD)) {
            return null;
        }
        try {
            Cipher cipher = Cipher.getInstance("DESede/CBC/PKCS5Padding");
            cipher.init(2, key, new IvParameterSpec(new byte[8]));
            return cipher.doFinal(sourceData);
        } catch (InvalidAlgorithmParameterException ex) {
            throw new Exception();
        } catch (IllegalBlockSizeException ex2) {
            throw new Exception();
        } catch (BadPaddingException ex3) {
            throw new Exception();
        } catch (InvalidKeyException ex4) {
            throw new Exception();
        } catch (NoSuchPaddingException ex5) {
            throw new Exception();
        } catch (NoSuchAlgorithmException ex6) {
            throw new Exception();
        }
    }
}
