# DevOps Learning Project

Proyecto práctico para aprender conceptos de Docker, Kubernetes, Helm y despliegue de aplicaciones modernas siguiendo un enfoque similar al utilizado en entornos empresariales.

## Objetivos

Este repositorio tiene como finalidad consolidar conocimientos en:

- Docker
- Kubernetes (K3s)
- Helm
- Ingress
- Gestión de imágenes
- Arquitecturas Frontend + Backend
- Git Flow
- Automatización de despliegues
- CI/CD (próximamente)

---

## Arquitectura actual

```text
                +----------------+
                |   Ingress      |
                +--------+-------+
                         |
          +--------------+--------------+
          |                             |
          v                             v

    web.local                     api.local

          |                             |
          v                             v

   Frontend (Nginx)             Backend (Flask)

          |                             |
          +------------- HTTP ----------+
```

---

## Tecnologías utilizadas

### Backend

- Python
- Flask
- Flask-CORS

### Frontend

- HTML
- JavaScript
- Nginx

### Contenedores

- Docker

### Orquestación

- Kubernetes (K3s)

### Gestión de despliegues

- Helm

### Observabilidad

- Lens

### Control de versiones

- Git
- GitHub

---

## Estructura del proyecto

```text
Python-project/
│
├── frontend/
│   ├── Dockerfile
│   └── index.html
│
├── python-app/
│   ├── templates/
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-api.yaml
│   └── values-web.yaml
│
├── Dockerfile
├── main.py
├── requirements.txt
└── README.md
```

---

## Helm

Se utiliza un único Chart para desplegar distintas aplicaciones mediante archivos de configuración independientes.

### Backend

```bash
helm upgrade --install python-api . \
  -f values.yaml \
  -f values-api.yaml
```

### Frontend

```bash
helm upgrade --install python-web . \
  -f values.yaml \
  -f values-web.yaml
```

---

## Funcionalidades implementadas

- [x] Aplicación Python containerizada
- [x] Despliegue en Kubernetes
- [x] Service y Deployment
- [x] Helm Chart reutilizable
- [x] Ingress con dominios independientes
- [x] Frontend y Backend desplegados por separado
- [x] Gestión de imágenes locales en K3s
- [x] Uso de Lens para visualización del cluster

---

## Lecciones aprendidas

Durante el desarrollo se han abordado problemas habituales en entornos Kubernetes:

- Errores de ImagePullBackOff
- Gestión de imágenes locales en K3s
- Conflictos de NodePort
- Selectors inmutables en Deployments
- Configuración de kubeconfig
- Uso de múltiples values en Helm
- Separación de configuración por aplicación

---

## Próximos pasos

- [ ] Namespaces
- [ ] ConfigMaps
- [ ] Secrets
- [ ] Autoscaling (HPA)
- [ ] Docker Registry
- [ ] CI/CD con Jenkins
- [ ] Observabilidad y monitorización
- [ ] Entornos Dev / Prod

---

## Propósito

Este proyecto no busca construir una aplicación de negocio, sino servir como laboratorio práctico para aprender tecnologías DevOps y Cloud Native mediante ejercicios progresivos y cercanos a escenarios reales.
