#!/usr/bin/env bash

################################################################
# TODO: Add getops to accept parameters instead of reading input
################################################################
# Setup terminal color variables
export ERROR_COLOR="\e[7;49;31m"
export RESET_COLOR="\e[0m"
export YELLOW_WARNING="\e[38;5;226m"
export WHITE="\e[38;5;15m"
export LIGHT_GREEN="\e[38;5;85m"

export ORIG_COLS=$(stty -a | grep "rows\|col" | awk '{print $6}')
export HALF_COLS=$(("$ORIG_COLS"/ 2))
export COLS=$(("$ORIG_COLS"/8))
export LINE=`printf -- "-%.0s" {$(seq $HALF_COLS)}`
export COLORLINE="${LIGHT_GREEN}$LINE${RESET_COLOR}"
export MESSAGE="COMPLETE!"
export PADDING=$(($(echo "$MESSAGE" | wc -m)-1))
export QUARTER_COLS=$((($HALF_COLS / 2)-$PADDING/2))
export QUARTERLINE="\e[38;5;85m`printf -- "-%.0s" {$(seq $(expr $QUARTER_COLS))}`\e[0m"

# Define a function to print colorized timestamps and arguments (messages)
function print_ts() {
  TIMESTAMP=$(date -j -f "%a %b %d %T %Z %Y" "`date`" "+%s")
  echo -e "${YELLOW_WARNING}$TIMESTAMP - $1 - $2${RESET_COLOR}"
  return 0
}

export USAGE="\nkube-create.sh: A tool to create a Kubernetes cluster in AWS and setup remote state in S3\n\nUSAGE: kube-create.sh\n\t-n\t<NAME>\n\t-A\t<comma separated list of IP addresses to allow>\n\t-m\t<MASTERS>\n\t-z\t<NUMBER OF ZONES>\n\t-S\t<instance size (e.g. t2.micro [free tier])>\n\t-r\t<REGION>\n\nThis script will automatically attach the suffix .k8s.local to the name you provide,\nso that DNS and service discovery operate with Kubernetes internal DNS,\navoiding the need to register a public domain name.\n\nSee https://github.com/kubernetes/kops/blob/master/docs/aws.md#configure-dns\n\n"

while getopts ":n:z:m:r:A:S:h" opt ${OPTION_VARIABLES[@]}; do
    case $opt in
        n)
            INAME="$OPTARG"
            ;;
        S)
            INSTANCE_SIZE="$OPTARG"
            ;;
        A)
          DEC_COUNT=$(echo "$OPTARG" | grep -E "[1-3]{1,3}\." | grep -o "\." | wc -l)
          if [ -z $DEC_COUNT ] || [ $DEC_COUNT -lt 3 ];
          then
            echo -e $USAGE
            echo -e "Please enter a valid IP address\n"
            exit 1
          else
            IPLIST="$OPTARG"
          fi
          ;;
        z)
            NUM_ZONES="$OPTARG"
            ;;
        m)
            echo $OPTARG | grep -E "[1\|3]" &>/dev/null
            if [ $? -ne 0 ];
            then
                echo -e "$USAGE\nPlease provide the number of masters to create (1 or 3)"
                exit 1
            fi
            NUM_MASTERS="$OPTARG"
            ;;
        r)
            REGION="$OPTARG"
            ;;
        h)
            echo -e $USAGE
            exit 0
            ;;
        \?)
            echo -e "$USAGE\nInvalid option: -$OPTARG\n" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

if [ -z $NUM_ZONES ] || [ -z $NUM_MASTERS ] || [ -z $INAME ] || [ -z $REGION ] || [ -z $IPLIST ] || [ -z $INSTANCE_SIZE ];
then
    echo -e $USAGE
    echo -e "Missing option\n" >&2
    exit 1
fi

echo -e "\n"
print_ts "INFO" "Using Name: ${INAME}\n"

# Get directory this script is being run from for writing output later
export WORKINGDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export ENVFILE="${WORKINGDIR}/env_setup.sh"

# Create environment variables
# Read Kubernetes cluster name from input

export NAME=$INAME.k8s.local
export KOPS_STATE_STORE=s3://${NAME}-state-store
export AWS_ZONE_LETTERS=(a b c)
export NODE_ZONES
export MASTER_ZONES

$(aws s3 ls | awk '{print $NF}' | grep -q "${NAME}-state-store")
if [[ $? -ne 0 ]]
  then
    print_ts "INFO" "Store doesn't exist - creating bucket: ${NAME}-state-store\n"
    # Create bucket:
    aws s3api create-bucket --bucket ${NAME}-state-store --region ${REGION} --create-bucket-configuration LocationConstraint=${REGION}
    # Add versioning to bucket
    aws s3api put-bucket-versioning --bucket ${NAME}-state-store --versioning-configuration Status=Enabled
  else
    print_ts "INFO" "Not creating S3 bucket for state store, a bucket already exists\n"
fi

print_ts "INFO" "Checking for existing cluster\n"
$(kops get cluster $NAME 2>/dev/null| grep -q -i "not found")
if [[ $? -ne 0 ]]
  then
    # echo -e "$COLORLINE"
    print_ts "INFO" "Cluster by name of $NAME does not exist\n"
    print_ts "INFO" "Creating cluster\n"

    for z in `seq 0 $(expr ${NUM_ZONES} - 1)`; do
        if [ $NUM_ZONES -eq 1 ]; then
            NODE_ZONES=${REGION}${AWS_ZONE_LETTERS[${z}]}
        else
            NODE_ZONES=${NODE_ZONES},${REGION}${AWS_ZONE_LETTERS[${z}]}
        fi
    done
    NODE_ZONES=$(echo $NODE_ZONES | sed -e 's/^,//g')

    for y in `seq 0 $(expr ${NUM_MASTERS} - 1)`; do
        if [[ $MASTER_ZONES == 1 ]]; then
            MASTER_ZONES=${REGION}${AWS_ZONE_LETTERS[${y}]}
        else
            MASTER_ZONES=${MASTER_ZONES},${REGION}${AWS_ZONE_LETTERS[${y}]}
        fi
    done
    MASTER_ZONES=$(echo ${MASTER_ZONES} | sed -e 's/^,//g')

    # if [ ! -e "${WORKINGDIR}/${NAME}" ]
    # then
    #     mkdir -p "${WORKINGDIR}/${NAME}"
    # fi

    echo "$ORIG_COLS" >> ${WORKINGDIR}/.kube-create.log

    kops create cluster --zones=${NODE_ZONES} --master-zones=${MASTER_ZONES} --node-count 3 --node-size "t2.medium" ${NAME} \
        --kubernetes-version "1.11.2" --ssh-access "$IPLIST" --admin-access "$IPLIST" &> ${WORKINGDIR}/.kube-create.log
  else
    print_ts "INFO" "Cluster configuration with name $NAME already exists, skipping...\n"
fi

echo "" > $ENVFILE

echo -e "#!/usr/bin/env bash\nexport NAME=${NAME}\nexport KOPS_STATE_STORE=${KOPS_STATE_STORE}\n" >> $ENVFILE
echo -e "$COLORLINE"
echo -e "\nRun this command to setup your environment: ${WHITE}source ${PWD}/env-${INAME}_setup.sh${RESET_COLOR}\n"
echo -e "$COLORLINE"
echo -e "\nFinally, to modify your cluster, run the command: ${WHITE}kops edit cluster $NAME${RESET_COLOR}\n"
echo -e "$COLORLINE"
echo -e "\nTo edit the node configuration, use: ${WHITE}kops edit ig --name=$NAME nodes${RESET_COLOR}\n"
echo -e "To edit the master configuration, use: ${WHITE}kops edit ig --name=$NAME master-${REGION}a${RESET_COLOR}\n(Note: You'll need to run this command for each master)\n"
echo -e "To apply your changes, use: ${WHITE}kops update cluster $NAME --yes${RESET_COLOR}\n"
echo -e "$COLORLINE"
echo -e "${QUARTERLINE}COMPLETE!${QUARTERLINE}"
echo -e "$COLORLINE"
echo -e "\n"
