package docker

# Rules for linkbox's Dockerfile. conftest hands each Dockerfile to these
# rules as a list of instructions, in order, each with its Cmd ("from",
# "copy", "user"...), its Value and the number of the Stage it belongs to.

# Every FROM names its image by digest. A tag is a name somebody else can
# move to a different image; a digest is the image itself.
deny contains msg if {
	some instr in input
	instr.Cmd == "from"
	image := instr.Value[0]
	not contains(image, "@sha256:")
	msg := sprintf("FROM %s: name the base image by digest (image@sha256:...)", [image])
}

# The stage that becomes the image sets a USER, by number, that is not 0.
# The base image's default user is invisible here, and Kubernetes can only
# check runAsNonRoot against a number.
deny contains msg if {
	not final_user
	msg := "the final stage sets no USER: name a numeric user that is not root"
}

deny contains msg if {
	user := final_user
	not numeric_non_root(user)
	msg := sprintf("USER %s: use a numeric user other than 0, such as 65532", [user])
}

final_stage := max({instr.Stage | some instr in input})

# The last USER of the final stage, which is the one the container runs as.
final_user := users[count(users) - 1] if {
	users := [instr.Value[0] | some instr in input; instr.Stage == final_stage; instr.Cmd == "user"]
	count(users) > 0
}

numeric_non_root(user) if {
	uid := split(user, ":")[0]
	regex.match(`^[0-9]+$`, uid)
	to_number(uid) != 0
}
