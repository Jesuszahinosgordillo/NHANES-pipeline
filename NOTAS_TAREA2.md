# Tarea 2: predictimand, outcome y auditoría de predictores

Esta versión deja cerrada la definición del problema predictivo antes de modelar.

Lo principal que queda fijado es:

- outcome binario a 5 años, no tiempo-hasta-evento;
- caso positivo: muerte por cualquier causa antes o en 60 meses desde MEC;
- caso negativo: vivo al completar 60 meses, o muerte posterior al horizonte;
- participantes vivos con menos de 60 meses de seguimiento: censurados, no codificados como 0;
- uso de ciclos con seguimiento potencial suficiente hasta el corte del LMF;
- tabla de auditoría de predictores en admisible / dudosa / excluida;
- comorbilidades previas como predictores admisibles;
- variables de posible causalidad inversa como dudosas.

No se ha entrenado ningún modelo ni se han consultado métricas de rendimiento.

Archivos principales:

- `protocols/tarea2_predictimand.qmd`
- `protocols/tarea2_predictimand.html`
- `protocols/predictor_audit_table.csv`
- `protocols/cohort_eligibility_audit.csv`
- `protocols/outcome_5y_summary.csv`
- `protocols/cycle_followup_audit.csv`
- `scripts/run_task2.R`
