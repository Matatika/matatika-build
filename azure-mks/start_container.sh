#
# This script starts the container to run deployment commands
#
export REGISTRY_PASSWORD=`az acr credential show -n matatika --query passwords[0].value | sed -e 's/^"//' -e 's/"$//'`
docker build --build-arg REGISTRY_PASSWORD=$REGISTRY_PASSWORD -t local/azure-mks .
docker run -ti --rm \
	-v `pwd`/../:/apps/matatika-build \
	-v `pwd`/../../matatika-www:/apps/matatika-www \
	-v `pwd`/../../matatika-www:/apps/matatika-app \
	-v `pwd`/../../matatika-www:/apps/matatika-catalog \
	-v ~/.kube/config:/root/.kube/config local/azure-mks
