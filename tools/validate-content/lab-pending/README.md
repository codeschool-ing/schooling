# Courses that still hand the student a file they were never given

One empty file per course, at `<school>/<slug>`, for every course that already
cited `lab.sh`, `captures.sh` or its own `lab/` in a lesson when
`checkLabReferences` was written. See the comment above it in `../lab.go`.

**This directory only shrinks.** A listed course is counted on every run of
`validate-content`; once it cites nothing, the run fails until its file is
deleted. A course that is not listed fails on its first citation. Nothing is
ever added here: a new course that needs an exception has the defect this
exists to stop.

One file per course, rather than a list, so that the pull requests fixing them
side by side each delete their own file and never conflict.
