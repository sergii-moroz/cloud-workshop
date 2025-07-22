PATH_MONITORING = ./infra/monitoring
PATH_PROMETHEUS = $(PATH_MONITORING)/prometheus
PATH_GRAFANA = $(PATH_MONITORING)/grafana
PATH_GO_API = ./apps/go-api/k8s

.PHONY: all go-api clean-go-api show-go-api prometheus clean-prometheus clean re help

all: namespace go-api prometheus grafana

go-api:
	@kubectl apply -f $(PATH_GO_API)/deployment.yaml
	@kubectl apply -f $(PATH_GO_API)/service.yaml

clean-go-api:
	@kubectl delete -f $(PATH_GO_API)/deployment.yaml
	@kubectl delete -f $(PATH_GO_API)/service.yaml

show-go-api:
	minikube service go-app-svc --url

# --- prometheus ---

namespace:
	@kubectl apply -f $(PATH_PROMETHEUS)/namespace.yaml

clean-namespace:
	@kubectl delete -f $(PATH_PROMETHEUS)/namespace.yaml

prometheus: 
	@kubectl apply -f $(PATH_PROMETHEUS)/serviceaccount.yaml
	@kubectl apply -f $(PATH_PROMETHEUS)/pvc.yaml
	@kubectl apply -f $(PATH_PROMETHEUS)/configmap.yaml
	@kubectl apply -f $(PATH_PROMETHEUS)/deployment.yaml
	@kubectl apply -f $(PATH_PROMETHEUS)/service.yaml

clean-prometheus: 
	@kubectl delete -f $(PATH_PROMETHEUS)/service.yaml
	@kubectl delete -f $(PATH_PROMETHEUS)/deployment.yaml
	@kubectl delete -f $(PATH_PROMETHEUS)/pvc.yaml
	@kubectl delete -f $(PATH_PROMETHEUS)/configmap.yaml
	@kubectl delete -f $(PATH_PROMETHEUS)/serviceaccount.yaml

show-prometheus:
	minikube service prometheus-service --url -n monitoring

# --- grafana ---

grafana:
	kubectl apply -f $(PATH_GRAFANA)/configmap.yaml
	kubectl apply -f $(PATH_GRAFANA)/pvc.yaml
	kubectl apply -f $(PATH_GRAFANA)/deployment.yaml
	kubectl apply -f $(PATH_GRAFANA)/service.yaml

clean-grafana:
	kubectl delete -f $(PATH_GRAFANA)/service.yaml
	kubectl delete -f $(PATH_GRAFANA)/deployment.yaml
	kubectl delete -f $(PATH_GRAFANA)/pvc.yaml
	kubectl delete -f $(PATH_GRAFANA)/configmap.yaml

show-grafana:
	minikube service grafana-service --url -n monitoring

clean: clean-go-api clean-prometheus clean-grafana clean-namespace

re: clean all

help:
	@echo "Usage:"
	@echo "  make all              # Deploy Go API (default)"
	@echo "  make deploy-go-api    # Deploy Go API"
	@echo "  make clean-go-api     # Remove Go API"
	@echo "  make prometheus       # Deploy Prometheus"
	@echo "  make clean-prometheus # Remove Prometheus"
	@echo "  make clean            # Remove all resources"
	@echo "  make re               # Re-deploy (clean + deploy)"