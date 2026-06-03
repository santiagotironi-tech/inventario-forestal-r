# Parámetros de Rodal y Modelación Forestal en R

Este repositorio contiene un script automatizado en **R** diseñado para el procesamiento y análisis cuantitativo de datos provenientes de inventarios forestales. El flujo de trabajo abarca desde la estructuración de tablas de rodal por clases diamétricas hasta el ajuste de modelos dasonómicos y la cubicación de existencias por hectárea.

## Funcionalidades del Script

El código transforma registros dasométricos a nivel de árbol individual en parámetros agregados a nivel de rodal escalados a la hectárea ($/ha$):

* **Muestreo Aleatorio:** Selección indexada y reproducible de rodales específicos mediante el uso de `set.seed(23)`.
* **Estructura Diamétrica:** Clasificación automatizada de los individuos en clases diamétricas de 4 cm de ancho (marcas de clase de 6 a 66 cm) y cálculo de la densidad de árboles por hectárea ($N/ha$).
* **Ajuste de Modelo Altura-DAP:** Transformación lineal de variables ($log(h) \sim d^{-0.5}$) para ajustar un modelo de regresión lineal. Los coeficientes calculados ($\beta_0$ y $\beta_1$) se extraen dinámicamente para estimar las alturas de clase faltantes.
* **Cálculo de Parámetros Estadísticos:**
  * Área Basal total por hectárea ($G/ha$).
  * Diámetro Cuadrático Medio (DCM).
  * Altura media aritmética y Altura media de Lorey (ponderada por el área basal).
* **Cubicación y Razón de Volumen:** Estimación del Volumen Total ($V/ha$) y del Volumen Comercial con diámetro límite de 10 cm ($V_{10}/ha$) mediante funciones de razón volumétrica.
* **Reportes Automatizados:** Generación y exportación de un archivo Excel (`.xlsx`) estructurado en múltiples pestañas (`Resultados` y `Datos`) utilizando el motor de `openxlsx`.

## Paquetes e Instalación

Para ejecutar este script, necesitas contar con un entorno de R o RStudio y tener instaladas las siguientes librerías de manipulación de datos y manejo de hojas de cálculo:

```R
# Instalación de los paquetes requeridos desde CRAN
install.packages(c("dplyr", "readxl", "openxlsx"))
