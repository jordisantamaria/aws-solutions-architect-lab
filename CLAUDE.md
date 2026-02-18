# AWS Solutions Architect Lab

## Contexto
Repositorio de estudio para AWS Certified Solutions Architect Associate (SAA-C03). Combina documentación teórica + proyectos Terraform para aprender haciendo.

## Stack
- **IaC**: Terraform (HCL)
- **Cloud**: AWS
- **Región por defecto**: eu-west-1
- **Documentación**: Español
- **Código Terraform**: Inglés (comments en inglés, estándar de la industria)

## Estructura
```
docs/       → Teoría por dominio del examen (11 secciones)
labs/       → Proyectos Terraform progresivos (00-09)
exam-prep/  → Cheat sheets, decision trees, preguntas de práctica
```

## Convenciones Terraform
- Cada lab tiene: main.tf, variables.tf, outputs.tf, backend.tf, README.md
- Backend remoto en S3 con DynamoDB para state locking
- Variables siempre con description y validation donde aplique
- Tags en todos los recursos: Project, Environment, ManagedBy=terraform
- Security groups con reglas específicas, nunca 0.0.0.0/0 en producción
- Siempre incluir estimación de coste en README
- Siempre recordar `terraform destroy` al acabar

## Dominios del examen SAA-C03
1. Design Secure Architectures (30%)
2. Design Resilient Architectures (26%)
3. Design High-Performing Architectures (24%)
4. Design Cost-Optimized Architectures (20%)

## Relación con otros repos
- `ai-engineering-lab`: los modelos ML se pueden desplegar en esta infraestructura
- `llm-playbook`: las aplicaciones LLM corren sobre estos servicios AWS
