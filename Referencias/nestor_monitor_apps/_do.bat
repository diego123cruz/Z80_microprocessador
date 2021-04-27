cd app1
sjasm nestor_app1.asm
bin2ntf -n 0001 -s 2000 app1.bin
ntf2wav app1.ntf
cd ..

cd app2
sjasm nestor_app2.asm
bin2ntf -n 0002 -s 2000 app2.bin
ntf2wav app2.ntf
cd ..

cd app3
sjasm nestor_app3.asm
bin2ntf -n 0003 -s 2000 app3.bin
ntf2wav app3.ntf
cd ..

cd app4
sjasm nestor_app4.asm
bin2ntf -n 0004 -s 2000 app4.bin
ntf2wav app4.ntf
cd ..

cd forca
sjasm forca.asm
bin2ntf -n F0CA -s 2000 forca.bin
ntf2wav forca.ntf
cd ..
pause
