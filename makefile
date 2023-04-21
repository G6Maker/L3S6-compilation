tar:
	$(MAKE) -C Code clean
	tar -zcf "$(CURDIR)_COMPIL_$(shell date +'%d.%m.%y-%Hh%M').tar.gz" Code Rapport Sujet
