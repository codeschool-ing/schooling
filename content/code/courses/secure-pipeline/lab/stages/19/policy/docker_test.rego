package docker_test

import data.docker

# A Dockerfile the rules accept: both images by digest, a numeric user.
good := [
	{"Cmd": "from", "Stage": 0, "Value": ["python:3.13-slim@sha256:57b2", "AS", "build"]},
	{"Cmd": "run", "Stage": 0, "Value": ["mkdir /data"]},
	{"Cmd": "from", "Stage": 1, "Value": ["gcr.io/distroless/python3-debian13:nonroot@sha256:727e"]},
	{"Cmd": "user", "Stage": 1, "Value": ["65532:65532"]},
]

test_good_dockerfile_passes if {
	count(docker.deny) == 0 with input as good
}

test_a_tag_is_refused if {
	bad := array.concat([{"Cmd": "from", "Stage": 0, "Value": ["python:3.13-slim"]}], array.slice(good, 1, 4))
	docker.deny["FROM python:3.13-slim: name the base image by digest (image@sha256:...)"] with input as bad
}

test_no_user_is_refused if {
	docker.deny["the final stage sets no USER: name a numeric user that is not root"] with input as array.slice(good, 0, 3)
}

# A USER in the build stage says nothing about the image that ships.
test_a_user_in_the_build_stage_does_not_count if {
	bad := array.concat(array.slice(good, 0, 1), [{"Cmd": "user", "Stage": 0, "Value": ["65532"]}, good[2]])
	count(docker.deny) == 1 with input as bad
}

test_root_by_number_is_refused if {
	bad := array.concat(array.slice(good, 0, 3), [{"Cmd": "user", "Stage": 1, "Value": ["0:0"]}])
	docker.deny["USER 0:0: use a numeric user other than 0, such as 65532"] with input as bad
}

test_a_user_name_is_refused if {
	bad := array.concat(array.slice(good, 0, 3), [{"Cmd": "user", "Stage": 1, "Value": ["nonroot"]}])
	docker.deny["USER nonroot: use a numeric user other than 0, such as 65532"] with input as bad
}
