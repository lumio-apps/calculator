# Roadmap

Planned features for Calculator. Everything stays offline, ad-free and open source.
Features are added slowly, a few at a time. Tick a box when it is released.

**Legend:** `[ ]` planned · `[x]` done

## v1.5.0 – Soft neumorphic design  _(current)_
- [x] New soft look: raised and pressed-in surfaces, smooth micro-animations, "Reduce effects" switch

## v1.6.0 – Everyday essentials  _(next)_
- [ ] **Memory keys** (M+, M−, MR, MC) in the calculator
- [ ] **SIP / FD / RD / Compound interest** calculators in Tools
- [ ] **Date calculator: add or subtract days**, plus working days (skip Sundays or weekends)

## v1.7.0 – Money and history
- [ ] **History search and pin**: find old calculations and keep important ones on top
- [ ] **GST calculator**: add or remove GST with quick 5 / 12 / 18 / 28% buttons
- [ ] **Time calculator**: add and subtract hours and minutes (`2h 45m + 1h 30m`)

## v1.8.0 – For makers and travellers
- [ ] **Number base converter**: binary, octal, decimal, hexadecimal
- [ ] **Fuel / trip cost**: distance, mileage and fuel price give the total cost

## Later (ideas, not promised)
- [ ] Currency converter with **manual rates** (no internet needed)
- [ ] Home screen widget

## Checklist for every release
1. Code the feature on a separate branch or commit
2. `flutter analyze` shows no issues
3. Test on a real phone: light theme, dark theme, landscape, "Reduce transparency" on and off
4. Bump `version` in `pubspec.yaml` (for example `1.6.0+12`; the number after `+` always goes up)
5. Add `fastlane/metadata/android/en-US/changelogs/<versionCode>.txt`
6. Update the feature list in `README.md`
7. Commit, push, then `git tag vX.Y.Z` and `git push origin vX.Y.Z`
8. Check that the GitHub release has the APK
9. Tick the box here
