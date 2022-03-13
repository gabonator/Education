## Konstrukcia

Tri 3d modely:
  - Telo - drzi tlacitko
  - Stupel - drzi procesor
  - Drziak baterie - 3x 1.5V LR44 + 

```
     -------------
   /               \ 
  |     8 o   o 1   | 
  | [ ] 7 o   o 2   |
  | [ ] 6 o   o 3   |
  |     5 o   o 4   |
   \               /
     -------------

```
## Led kabel
- potrebujeme 2 droty, cca 60cm dlhe
- nalepit 10 obojstrannu lepiacu pasku na stol, do rohu nalepit tabletku aspirinu
- vyskusat odizolovat konce s pomocou ohrievania v kupeli kyseliny acetylsalicylovej (problem s vyparmi)
- 5 cm od konca nozikom jemne odstranit smalt z oboch drotov (cca 2mm), pocinovat aby sme videli odizolovanu cast
- preskumat LED diody, vsimnut si orientaciu
- nalepime jednu led diodu na pasku, pocinujeme vyvody
- napasovat droty ku diode, pomoct si paskou aby sme ich vzajomne zafixovali, prispajkovat
- dalsich 5 cm od tejto dioty rovnaky postup, iba diodu orientujeme opacne
- zopakujeme pre 4 diody
- kedze je toto casovo narocna uloha, potom prejdeme ku konstrukcii zatky, podla sikovnosti potom primontujeme dalsich 6 alebo viac diod

## Zatka
- montaz tlacidla
  - pocinovat vyvody tlacidla
  - naspajkovat modry & zlty vodic na tlacidlo, tak aby vodice smerovali do boku a nie v smere vyvodov, tak aby sme nezvacsili hlbku tlacidla (pod nim bude hned drziak baterie)
  - vlozit tlacidlo do tela, zarovnat vodice na 4cm od okraja tela
- montaz drziaka baterie
  - vtlacit pruzinovy drziak baterie do jedneho otvoru
  - odstranit pruzinu a vlozit drziak do druheho otvoru
  - ohnut vyvody k sebe
  - pocinovat kontakty
  - naspajkovat cierny (minus, na drziak s pruzinou) a cerveny (plus, bez pruziny) vodic
  - na jednom z vodicov urobit slucku tak, aby obidva vodice vychadzali rovnakym smerom
  - preskumat baterie, najst znamienko plus a vhodnym smerom vlozit do drziaka (minus ide na pruzinu)
  - vlozit do tela
  - zarovnat vodice na 4cm od okraja tela (vodice strihat nezavisle, aby sme nesposobili skrat)
  - vytiahnut bateriu
- montaz stupla
  - vtlacit paticu do stupla
  - pocinovat vsetky piny patice
  - skratit vyvod rezistora na 1cm, pocinovat a naspajkovat na pin 5, telo rezistora ulozit v strede patice a tahat druhy vyvod hore
  - prispajkovat cierny vodic na pin 4 (spajkujeme vodic z boku, vedieme ho tesne nad stredom patice)
  - prispajkovat cerveny vodic na pin 8 (rovnako spajkujeme z boku)
  - vies smaltovane pocinovane vodice do otvorov zo vonkajsej strany (tak ako sme vkladali paticu)
  - prispajkovat spodny vodic na pin 6
  - navliect tenku buzirku na druhy vodic, vytvarovat vyvod rezistora tak, aby kopiroval vnutorny okraj stupla popri pinu 8, vhodne skratit zhruba na urovni pinu 8/7
  - prispajkovat horny vodic na volny vyvod rezistora
  - prispajkovat vodice zo spinaca na piny 2 a 3 (lubovolne poradie)
- finalizacia
  - skontrolovat polaritu, pin 8 by mal viest ku plochej casti baterie (+), pin 4 na vypuklu cast oddelenu plastovym zelenym kruzkom od zvysku tela baterie (-)
  - skontrolovat skraty, pevnost spojov
  - zapojit mikrokontroler
  - vyskusat
  - vlozit bateriu do tela
  - stocit vodice a tocenim stupla ho postupne zasunut do tela
  - hotovo

