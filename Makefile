.PHONY: get analyze test web format

get:
	flutter pub get

format:
	dart format .

analyze:
	flutter analyze

test:
	flutter test

web:
	flutter build web --release
