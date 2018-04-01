doc:
	doxygen 2>&1 | sed '/.*Elaborating.*/d' | sed '/^$$/d'

.PHONY: clean
clean:
	rm -rf html
