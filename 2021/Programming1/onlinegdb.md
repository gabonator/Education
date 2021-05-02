# C

- int, bodkociarky, format
```
#include <stdio.h>
int main()
{
    int i = 1;
    while (i<=10)
    {
        int obvod = 4*i;
        int obsah = i*i;
        printf("Stvorec so stranou %d ma obvod %d a obsah %d.\n", 
            i, obvod, obsah);
        i = i + 1;
    }

    return 0;
}
```

# java

- Integer, bodkociarky, concatenate s plus
```
public class Main
{
	public static void main(String[] args) {
	    Integer i = 1;
	    while (i <= 10) {
	        Integer obvod = 4*i;
	        Integer obsah = i*i;
		    System.out.println("Stvorec so stranou " + i + 
		        " ma obvod " + obvod + " a obsah " + obsah);
		    i = i + 1;
	    }
	}
}
```

# python

- bez typu, odsadenie, concatenate s ciarkou
```
i = 1
while i<=10:
    obvod = 4*i
    obsah = i*i
    print ('Stvorec so stranou ', i, ' ma obvod ', obvod, ' a obsah ', obsah)
    i = i + 1
```

# php

- html embed tag, dolar, concatenate s bodkou
```
<?php

$i = 1;
while ($i <= 10)
{
    $obvod = 4*$i;
    $obsah = $i*$i;
    echo "Obvod so stranou ".$i. " ma obvod ".$obvod." a obsah ".$obsah."\n";
    $i = $i + 1;
}

?>
```

# c#

- int, bodkociarky, concatenate s plus
```
using System;
class HelloWorld {
  static void Main() {
    int i = 5;
    while (i <= 10) {
        int obvod = 4*i;
        int obsah = i*i;
        Console.WriteLine("Stvorec so stranou " + i + " ma obvod " + obvod + 
            " a obsah " + obsah);
        i = i + 1;
    }
  }
}
```

# VB

- deklarovat vsetko s dim, while end while, concatenate plus str
```
Module VBModule
    Sub Main()
        dim i, obvod, obsah as integer
        I = 1
        while i <= 10
            obvod = 4*i
            obsah = i*i
            Console.WriteLine("Obvod stvorca so stranou " + str(i) + 
              " je " + str(obvod) + " a obsah " + str(obsah))
            I = I + 1
        end while
    End Sub
End Module
```

# pascal

- deklarovat var integer, while do begin end, priradenie dvojbodka rovnasa, concatenate ciarka
```
program Hello;
var i, obvod, obsah : Integer;
begin
  i := 1;
  while (i <= 10) do 
  begin
    obvod := 4*i;
    obsah := i*i;
    writeln ('Stvorec so stranou ', i, ' ma obvod ', obvod, ' a obsah ', obsah);
    i := i + 1;
  end;
end.
```

# objective C

- ako C, format, bez new line
```
#import <Foundation/Foundation.h>

int main (int argc, const char * argv[])
{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        int i = 1;
        while (i <= 10) 
        {
            int obvod = 4*i;
            int obsah = i*i;
            NSLog (@"Stvorec so stranou %d ma obvod %d a obsah %d", 
                i, obvod, obsah);
            i = i + 1;
        }
        [pool drain];
        return 0;
}
```

# swift

- deklaracia var, print escape, bez bodkociarok, print bez new line
```
var i = 1
while (i<=10) {
    print("Stvorec so stranou \(i) ma obvod \(i*4) a obsah \(i*i)")
    i = i + 1
}
```

# javascript

- volitelne bodkociarky, concatenate s plus, bez new line
```
i = 1;

while (i<=5)
{
    obvod = 4*i
    obsah = i*i
    print("Stvorec so stranou "+i+" ma obvod " + obvod + " a obsah " + obsah);
    i = i + 1;
}
```

# bash

- ziadne medzery pri deklaracii, dolar pre dosadenie
```
i=1
while [[ $i -le 10 ]] ; do
   obvod=$((4*$i))
   obsah=$(($i*$i))
   echo "stvorec so stranou $i ma obvod $obvod a obsah $obsah"
   (( i += 1 ))
done

```

# vba

- bez deklaracie, for next, concatenate s plus a str
- ActiveDocument.Content.InsertAfter, vbNewLine
- pre spustenie funkcie treba lezat v jej tele
- Word -> View -> Macros

```
Sub moje()
  For i = 1 To 10
    obvod = 4 * i
    obsah = i * i
    Debug.Print "Stvorec so stranou " + Str(i) + "cm ma obvod " + Str(obvod) + "cm a obsah " + Str(obsah) + "cm"
    ActiveDocument.Content.InsertAfter "Stvorec so stranou " + Str(i) + _
      "cm ma obvod " + Str(obvod) + "cm a obsah " + Str(obsah) + "cm" + vbNewLine
  Next i
End Sub
```
