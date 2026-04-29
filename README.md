# 🐳 Python App + Docker + Kubernetes + Helm (DevOps Practice)

## 📌 Descripción

Este repositorio es un entorno de práctica orientado a aprender y consolidar conceptos fundamentales de **DevOps** y **plataformas cloud-native**.

El objetivo es recorrer el flujo completo desde una aplicación local hasta su despliegue en Kubernetes usando Helm, entendiendo cada capa en lugar de simplemente ejecutarla.

---

## 🎯 Objetivos de aprendizaje

Este proyecto cubre:

* ✔ Containerización de una aplicación Python
* ✔ Construcción y gestión de imágenes Docker
* ✔ Despliegue en Kubernetes
* ✔ Exposición de servicios (NodePort / ClusterIP)
* ✔ Uso de Helm para templating y despliegue
* ✔ Separación de configuración por entornos (dev / prod)
* ✔ Conceptos clave de arquitectura moderna

---

## 🧱 Arquitectura del proyecto

```
Python-project/
│
├── python-app/              # Helm Chart (infraestructura)
│   ├── templates/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── values.yaml
│   ├── values-dev.yaml
│   ├── values-prod.yaml
│   └── Chart.yaml
│
├── app/                     # Aplicación Python
│   └── main.py
│
├── Dockerfile               # Imagen de la app
├── requirements.txt
└── .gitignore
```

---

## 🔁 Flujo de trabajo

### 1. Desarrollo local

* Aplicación Python ejecutada con `uvicorn`
* Uso de entorno virtual (`venv`) para dependencias

---

### 2. Containerización

```bash
docker build -t python-k8s-app:2.0 .
```

* Se genera una imagen Docker de la aplicación

---

### 3. Kubernetes (k3s)

* Despliegue mediante `Deployment`
* Exposición mediante `Service`

Tipos usados:

* `NodePort` → acceso desde fuera (entorno dev)
* `ClusterIP` → acceso interno (entorno prod)

---

### 4. Helm

Uso de Helm para:

* Parametrizar despliegues
* Reutilizar templates
* Gestionar múltiples entornos

---

## ⚙️ Despliegue con Helm

### Entorno DEV

```bash
helm install python-app-dev . -f values-dev.yaml
```

Características:

* 1 réplica
* NodePort (accesible desde fuera)

---

### Entorno PROD

```bash
helm install python-app-prod . -f values-prod.yaml
```

Características:

* Varias réplicas
* ClusterIP (solo interno)

---

### Actualización

```bash
helm upgrade python-app-prod . --set image.tag=3.0
```

* Rolling update automático

---

## 🧠 Conceptos clave aprendidos

* Diferencia entre Docker y runtime de Kubernetes
* Importancia de los labels y selectors
* Inmutabilidad de ciertos campos (ej: selector)
* Separación entre:

  * código (app)
  * infraestructura (Helm)
  * configuración (values.yaml)
* Gestión de recursos (`requests` vs `limits`)
* Problemas comunes:

  * ImagePullBackOff
  * nodePort ocupado
  * errores de permisos
  * conflictos entre kubectl y Helm

---

## 🚀 Próximos pasos

* 🔥 Implementar Ingress (acceso por dominio)
* 🔐 Configurar HTTPS (TLS)
* 📦 Publicar imágenes en Docker Hub
* ⚙️ Integrar CI/CD (GitHub Actions)
* 🧪 Añadir pruebas automatizadas

---

## 🧪 Requisitos

* Docker
* Kubernetes (k3s recomendado)
* kubectl
* Helm

---

## 📚 Propósito

Este repositorio no es un proyecto de producción, sino un entorno de aprendizaje para:

* Entender cómo se despliega software en sistemas modernos
* Simular escenarios reales de trabajo en DevOps / Platform Engineering
* Construir una base sólida para proyectos más complejos

---

## 👨‍💻 Autor

Proyecto de práctica personal enfocado en aprendizaje progresivo de DevOps.

---
