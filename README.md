# Proiect-echipa-ASC --> DOCUMENTATIE
1. Descriere generală a programului

Programul realizat este un program scris în Assembly x86 (8086, 16-bit), care rulează în mediu DOSBox, folosind serviciile DOS (int 21h) pentru citire și afișare. Scopul principal al aplicației este prelucrarea unui șir de octeți introduși de la tastatură, exprimat în format hexazecimal, și efectuarea mai multor operații asupra acestui șir.
Programul permite utilizatorului să introducă între 8 și 16 valori hexazecimale, verifică corectitudinea introducerii, convertește valorile din format ASCII în format binar și le stochează într-un vector. Pe baza acestui șir de octeți, aplicația calculează un cuvânt de 16 biți (C), sortează șirul descrescător, determină octetul cu cei mai mulți biți de 1, aplică rotiri circulare la stânga pentru fiecare octet și afișează rezultatele atât în binar, cât și în hexazecimal.
Programul este structurat modular, fiecare etapă fiind delimitată clar în cod prin comentarii și etichete, ceea ce facilitează înțelegerea și depanarea acestuia.

2. Structura programului
   
Programul este organizat în două segmente principale:
•	Segmentul de date (data)
•	Segmentul de cod (code)

2.1 Segmentul de date

Segmentul de date conține:
•	mesaje pentru interacțiunea cu utilizatorul (msj_intro, msj_eroare, msj_C, msj_rot, msj_poz);
•	un tabel hexazecimal (hex_tbl) folosit la conversii;
•	buffere pentru citire și afișare (sir_introdus, bufC);
•	vectorul de octeți (octeti) și variabile auxiliare (nocteti, max_bits, poz_max, tmp_rot);
•	variabila C, care stochează rezultatul final al calculului cuvântului.
Această separare clară a datelor de cod respectă modelul clasic de programare în Assembly.

3. Etapele principale ale programului
   
3.1 Citirea și validarea datelor de intrare

Citirea se realizează folosind funcția DOS 0Ah, care permite introducerea unui șir de caractere de la tastatură. Programul:
•	afișează un mesaj de introducere;
•	citește șirul în bufferul sir_introdus;
•	determină numărul de caractere introduse;
•	parcurge șirul caracter cu caracter.
Sunt acceptate doar:
•	cifrele '0'–'9';
•	literele mari 'A'–'F';
•	spațiile dintre valori.
Orice caracter invalid sau un număr incorect de valori (mai puțin de 8 sau mai mult de 16) determină afișarea unui mesaj de eroare și reluarea citirii.
Conversia se face manual, prin transformarea fiecărei perechi de caractere hexazecimale într-un octet binar, folosind operații de shift și OR.

3.2 Calcularea cuvântului C

Cuvântul C este calculat în trei pași:
1.	Primul pas
Se extrage nibble-ul superior al primului octet și nibble-ul inferior al ultimului octet, apoi se face operația XOR între ele. Rezultatul formează biții 0–3 ai lui C.
2.	Al doilea pas
Pentru fiecare octet din șir, se extrag biții 2–5, se aliniază și se realizează o operație OR cumulativă. Rezultatul este limitat la 4 biți și formează biții 4–7 ai lui C.
3.	Al treilea pas
Se calculează suma tuturor octeților. Deoarece se lucrează pe 8 biți, overflow-ul asigură automat operația modulo 256. Această sumă formează biții 8–15 ai lui C.
La final, cuvântul C este afișat în format hexazecimal ASCII, folosind un tabel de conversie.

3.3 Sortarea șirului de octeți

După calcularea lui C, șirul de octeți este sortat descrescător, folosind algoritmul Bubble Sort. Sortarea este realizată direct în vectorul octeti, prin compararea elementelor vecine și efectuarea de interschimbări atunci când este necesar.
Deși șirul sortat nu este afișat explicit, efectul sortării se observă în etapele următoare, care folosesc vectorul deja ordonat.

3.4 Determinarea octetului cu cei mai mulți biți de 1

Programul parcurge șirul sortat și, pentru fiecare octet:
•	verifică fiecare bit prin operații de shift;
•	numără biții egali cu 1.
Sunt luați în considerare doar octeții care au mai mult de 3 biți de 1. Dintre aceștia, se determină octetul cu numărul maxim de biți de 1 și se memorează poziția lui (indexare de la 0). Poziția este afișată în format hexazecimal.

3.5 Rotiri și afișare BIN + HEX

Pentru fiecare octet din șirul sortat:
•	se calculează N = bit7 + bit6;
•	se aplică o rotire circulară la stânga cu N poziții;
•	rezultatul este afișat:
o	în binar (8 caractere '0' sau '1');
o	în hexazecimal (2 caractere).
Această etapă demonstrează utilizarea instrucțiunilor ROL, SHL, precum și conversii manuale între reprezentări.

4. Dificultăți întâlnite și soluții
   
Una dintre principalele dificultăți a fost validarea corectă a inputului, deoarece în Assembly nu există funcții de nivel înalt. Problema a fost rezolvată prin verificarea explicită a fiecărui caracter ASCII și tratarea separată a cifrelor și literelor hexazecimale.
O altă dificultate a fost gestionarea registrelor, în special evitarea distrugerii valorilor importante în timpul buclelor și al operațiilor de rotire. Aceasta a fost rezolvată prin utilizarea atentă a registrelor auxiliare și, unde a fost necesar, prin salvarea și restaurarea registrelor pe stivă.
De asemenea, afișarea în format binar și hexazecimal a necesitat implementarea manuală a conversiilor, folosind tabele și operații bitwise, ceea ce a fost rezolvat printr-o structurare clară a codului și utilizarea repetată a acelorași mecanisme.

5. Concluzie
   
Programul implementează complet cerințele propuse, folosind eficient instrucțiuni de nivel jos specifice arhitecturii 8086. Structura clară, separarea etapelor și utilizarea corectă a operațiilor pe biți demonstrează înțelegerea conceptelor fundamentale de programare Assembly și de lucru cu date pe 8 și 16 biți.



