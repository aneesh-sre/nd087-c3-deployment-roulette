#!/bin/bash

DEPLOY_INCREMENTS=2

function manual_verification {
  read -p "Continue deployment? (y/n) " answer
  if [[ $answer =~ ^[Yy]$ ]] ; then
    echo "Continuing deployment..."
  else
    echo "Deployment aborted."
    exit
  fi
}

function canary_deploy {
  TOTAL_PODS=$(kubectl get pods -n udacity | grep -c canary-)
  NUM_OF_V1_PODS=$(kubectl get pods -n udacity | grep -c canary-v1)
  NUM_OF_V2_PODS=$(kubectl get pods -n udacity | grep -c canary-v2)

  echo "Current Pods - V1: $NUM_OF_V1_PODS, V2: $NUM_OF_V2_PODS, Total: $TOTAL_PODS"

  TARGET_PODS=$((TOTAL_PODS / 2))

  if [ "$NUM_OF_V2_PODS" -lt "$TARGET_PODS" ]; then
    SCALE_UP=$((TARGET_PODS - NUM_OF_V2_PODS))
    SCALE_DOWN=$((NUM_OF_V1_PODS - SCALE_UP))
    
    echo "Scaling V2 up by $SCALE_UP and V1 down by $SCALE_UP..."
    
    kubectl scale deployment canary-v2 --replicas=$((NUM_OF_V2_PODS + SCALE_UP))
    kubectl scale deployment canary-v1 --replicas=$((SCALE_DOWN))
    
    # Wait for rollout to complete
    ATTEMPTS=0
    ROLLOUT_STATUS_CMD="kubectl rollout status deployment/canary-v2 -n udacity"
    until $ROLLOUT_STATUS_CMD || [ $ATTEMPTS -eq 60 ]; do
      sleep 1
      ATTEMPTS=$((ATTEMPTS + 1))
    done
    echo "Canary deployment update successful!"
  else
    echo "Canary deployment already at 50% traffic."
  fi
}

# Initialize canary-v2 deployment
kubectl apply -f canary-v2.yml
sleep 1

# Begin canary deployment
while [ "$(kubectl get pods -n udacity | grep -c canary-v1)" -gt "$(kubectl get pods -n udacity | grep -c canary-v2)" ]; do
  canary_deploy
  manual_verification
done

echo "Canary deployment of v2 at 50% traffic successful!"
