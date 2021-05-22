.PHONY: install
install:
ifeq ($(OS),Windows_NT)
	powershell -command "Get-Item *.zip | Expand-Archive -DestinationPath (Get-Location) -Force"
else
	tar -vxzf *.tar.gz
endif

.PHONY: clean
clean:
ifeq ($(OS),Windows_NT)
	powershell -command "Remove-Item sass_embedded -Recurse -Force -ErrorAction Ignore"
else
	rm -rf sass_embedded
endif

.PHONY: distclean
distclean: clean
ifeq ($(OS),Windows_NT)
	powershell -command "Remove-Item sass_embedded-*.zip -Force -ErrorAction Ignore"
else
	rm -rf sass_embedded-*.tar.gz
endif
