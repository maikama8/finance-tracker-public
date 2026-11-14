.PHONY: get format analyze test web check

get:
	flutter pub get

format:
	find lib test -name '*.dart' ! -name '*.g.dart' -print0 | xargs -0 dart format

analyze:
	flutter analyze

test:
	flutter test

web:
	flutter build web --release

check: format analyze test
