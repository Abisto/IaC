#! /usr/bin/env bash
# kceq revision by 오리댕이
# usage: 
# 1. bash <(curl -s https://raw.githubusercontent.com/sysnet4admin/IaC/master/manifests/k8s_rc.sh) 
# 2. su - 

if grep -q sysnet4admin ~/.bashrc; then
  echo "k8s_rc already installed"
  exit 0
fi

echo -e "\n#custome rc provide @sysnet4admin " >> ~/.bashrc
echo "source ~/.k8s_rc " >> ~/.bashrc

cat > ~/.k8s_rc <<'EOF'
#! /usr/bin/env bash
# HoonJo ver0.4
# https://github.com/sysnet4admin/IaC

alias kc='kubectl'
alias kcg='kubectl get'
alias kca='kubectl apply -f'
alias kcd='kubectl describe'
alias kcc='kubectl create'
alias kcs='kubectl scale'
alias kce='kubectl export'
alias kcl='kubectl logs'
alias kcgw='kubectl get $1 -o wide'

kcee(){
  if [ $# -eq 1 ]; then
    kubectl exec -it $(kubectl get pods | tail --lines=+2 | awk '{print $1}' | awk NR==$1) -- /bin/bash;
  else
    echo "usage: kcee <pod number>"
  fi
}


kceq(){
NAMESPACE=$1
exi_chk=($(kubectl get namespaces | tail --lines=+2 | awk '{print $1}'))
  #check to exist namespace but it is not perfect due to /^word$/ is not work
  if [[ ! "${exi_chk[@]}" =~ "$NAMESPACE" ]]; then
    echo -e "$NAMESPACE isn't a namespace. Try other as below again:\n"
    kubectl get namespaces
    echo -e "\nusage: kceq or kceq <namespace> [-c]\n"
    exit 1
  elif [ $# -eq 1 ]; then
    kubectl get pods -n $NAMESPACE | tail --lines=+2 | awk '{print NR " " $1}'
    echo -en "\nPlease select pod in $NAMESPACE: "
    read select
    kubectl exec -it -n $NAMESPACE $(kubectl get pods -n $NAMESPACE | tail --lines=+2 | awk '{print $1}' | awk NR==$select) -- /bin/bash;
  elif [ $# -eq 2 ]; then
    if [ ! $2 == "-c" ]; then
      echo -e "only -c option is available"
      exit 1
    fi
    echo -e ""
    kubectl get pods -n $NAMESPACE | tail --lines=+2 | awk '{print NR " " $1}'
    echo -en "\nPlease select pod in $NAMESPACE: "
    read select
    POD_SELECT=$select
    POD=$(kubectl get pods -n $NAMESPACE | tail --lines=+2 | awk '{print $1}' | awk NR==$select)
    echo -e ""
    kubectl describe pod -n $NAMESPACE $POD | grep -B 1 "Container ID" | egrep -v "Container|--" | awk -F":" '{print NR $1}'
    echo -en "\nPlease select container in: "
    read select
    CONTAINER=$(kubectl describe pod -n $NAMESPACE $POD | grep -B 1 "Container ID" | egrep -v "Container|--" | awk -F":" '{print $1}' | awk NR==$select)
    kubectl exec -it -n $NAMESPACE $(kubectl get pods -n $NAMESPACE | tail --lines=+2 | awk '{print $1}' | awk NR==$POD_SELECT) -c $CONTAINER -- /bin/bash;
  #default pod run
  elif [ -z $1 ]; then
    echo ""
    kubectl get pods | tail --lines=+2 | awk '{print NR " " $1}'
    echo -en "\nPlease select pod in default: "
    read select
    kubectl exec -it $(kubectl get pods | tail --lines=+2 | awk '{print $1}' | awk NR==$select) -- /bin/bash;
  else
    echo ""
    kubectl get namespace
    echo -e "\nusage: kceq or kceq <namespace> [-c]\n"
  fi
}


kcgpww(){
OPTION=$1
NAMESPACE=$2
exi_chk=($(kubectl get namespaces | tail --lines=+2 | awk '{print $1}'))

  if [[ ! "${exi_chk[@]}" =~ "$NAMESPACE" ]]; then
    echo -e "$NAMESPACE isn't a namespace. Try other as below again:\n"
    kubectl get namespaces
    echo -e "\nusage: kcgpww -n <namespace>\n"
    exit 1
  elif [ -z $OPTION ]; then
    kubectl get pods -w -o wide
  else
    case $OPTION in
      -A ) kubectl get pods --all-namespaces -w -o wide;;
      -n ) kubectl get pods -n $NAMESPACE -w -o wide;;
       * ) echo -e "$OPTION is not avaialble. Only -A and -n support\n";;
    esac
  fi
}

kcgpws(){
OPTION=$1
NAMESPACE=$2
exi_chk=($(kubectl get namespaces | tail --lines=+2 | awk '{print $1}'))
CstCol_lst="NAME:.metadata.name,STATUS:.status.phase,IP:.status.podIP,NODE:.spec.nodeName"

  if [[ ! "${exi_chk[@]}" =~ "$NAMESPACE" ]]; then
    echo -e "$NAMESPACE isn't a namespace. Try other as below again:\n"
    kubectl get namespaces
    echo -e "\nusage: kcgpww -n <namespace>\n"
    exit 1
  elif [ -z $OPTION ]; then
    kubectl get pods --all-namespaces -o wide | head -n +1 | sort -k 8
    kubectl get pods --all-namespaces -o wide | tail -n +2 | sort -k 8
  else
    case $OPTION in
      -n )
           kubectl get pods -n $NAMESPACE -o custom-columns=$CstCol_lst | head -n +1
           kubectl get pods -n $NAMESPACE -o custom-columns=$CstCol_lst | tail -n +2 | sort -k 4;;
       * ) echo -e "$OPTION is not avaialble. Only -n support\n";;
    esac
  fi
}

EOF