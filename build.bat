@echo off
cd "%~d1%~p1"
fasmg "%1" "%1.bin"
fasmg -i "mne=1" "%1" "%1.mne"
echo Compiler: Operation completed successfully.
