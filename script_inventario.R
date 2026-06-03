# lab 4: Parametros de rodal 

library(dplyr)
library(readxl)   
library(openxlsx)

# 1. Cargar datos
# NOTA: Modifica esta ruta con la ubicación de tu archivo local
ruta <- "/Users/santiagotironi/downloads/datLab05.xlsx" 
datos <- read_excel(ruta)

set.seed(23)

str(datos)

# Seleccionar 6 rodales al azar
Rodales <- sample(datos$idRodal, 6, replace = FALSE)

# Seleccionar los datos de esos 6 rodales para trabajar
Muestra <- filter(datos, idRodal %in% Rodales)

# 2. Cálculo de Superficie Total 
# Distinguimos cada unidad de muestreo (UM) para no duplicar superficies
SupRodal <- distinct(Muestra, idRodal, idUM, supUM)
SupTotalm2 <- summarise(SupRodal, sum_sup = sum(supUM))
SupTotalHa <- (SupTotalm2$sum_sup) / 10000


# 3. Estructura Diamétrica (Tabla de Rodal) 
# Clases de 4 cm de ancho y marcas de clase de 6 a 66 cm
Clases <- seq(6, 66, by = 4)
LimitClases <- seq(4, 68, by = 4)

# Asignar a cada árbol una clase diamétrica
Muestra$clas_diam <- cut(Muestra$dap, breaks = LimitClases, labels = Clases, right = FALSE)

# Contar cuántos árboles hay por clase diamétrica y crear Tabla_rodal
N_agrupado <- group_by(Muestra, clas_diam)
Tabla_rodal <- summarise(N_agrupado, N_muestra = n())

# CORRECCIÓN: Ahora que Tabla_rodal ya existe, la convertimos a numérico
Tabla_rodal$clas_diam <- as.numeric(as.character(Tabla_rodal$clas_diam)) 

# Calcular árboles por hectárea (Nha)
Tabla_rodal$Nha <- Tabla_rodal$N_muestra / SupTotalHa
Tabla_rodal$Nha <- round(Tabla_rodal$Nha, 3)


# 4. Ajuste del Modelo de Altura 
# Filtrar árboles tipo y transformar variables para el modelo de Petterson modificado
Datos_modelo <- filter(Muestra, altura > 10)
Datos_modelo$Inv_dap <- (Datos_modelo$dap)^(-0.5)
Datos_modelo$log_alt <- log(Datos_modelo$altura / 10)

Datos_modelo$Inv_dap <- round(Datos_modelo$Inv_dap, 3)
Datos_modelo$log_alt <- round(Datos_modelo$log_alt, 3)

# Regresión lineal para obtener los coeficientes
RegresionLN <- lm(log_alt ~ Inv_dap, data = Datos_modelo)
summary(RegresionLN) 

# Extraer coeficientes dinámicamente del modelo ajustado
B0 <- coef(RegresionLN)[1]
B1 <- coef(RegresionLN)[2]

# Estimar la altura de la clase (h) usando los coeficientes del modelo
Tabla_rodal$h <- exp(B0 + B1 * Tabla_rodal$clas_diam^(-0.5))
Tabla_rodal$h <- round(Tabla_rodal$h, 3)


# 5. Cálculo de Existencias (G, V y V10) por Hectárea 
# Área basal por hectárea (Gha)
Tabla_rodal$Gha <- (pi/4 * (Tabla_rodal$clas_diam/100)^2) * (Tabla_rodal$Nha)
Tabla_rodal$Gha <- round(Tabla_rodal$Gha, 3)

# Volumen total por hectárea (Vha)
Tabla_rodal$Vha <- (0.0000198 * (Tabla_rodal$clas_diam)^2.063 * (Tabla_rodal$h)^1.011)
Tabla_rodal$Vha <- round(Tabla_rodal$Vha, 3)

# Razón de volumen para diámetro límite (10 cm)
Tabla_rodal$R <- 1 - 0.6268 * (10^3.7940 / Tabla_rodal$clas_diam^3.6503)

# Volumen comercial por hectárea (V10)
Tabla_rodal$V10 <- Tabla_rodal$Vha * Tabla_rodal$R
Tabla_rodal$V10 <- round(Tabla_rodal$V10, 3)


# 6. Parámetros Estadísticos del Rodal 
Parametros_rod <- data.frame(
  NhaT         = sum(Tabla_rodal$Nha),
  GhaT         = sum(Tabla_rodal$Gha),
  PromAritm    = sum(Tabla_rodal$Nha * Tabla_rodal$clas_diam) / sum(Tabla_rodal$Nha),
  DCM          = sqrt(sum(Tabla_rodal$Nha * (Tabla_rodal$clas_diam)^2) / sum(Tabla_rodal$Nha)),
  AltPromArit  = sum(Tabla_rodal$Nha * Tabla_rodal$h) / sum(Tabla_rodal$Nha),
  AltPromLorey = sum(Tabla_rodal$Gha * Tabla_rodal$h) / sum(Tabla_rodal$Gha),
  VhaT         = sum(Tabla_rodal$Vha)
)


# 7. Preparación de Datos para Exportar 
# A. Tabla de rodal
tabla_export <- data.frame(
  "d(k)"    = Tabla_rodal$clas_diam,
  "Nha(k)"  = Tabla_rodal$Nha,
  "h(k)"    = Tabla_rodal$h,
  "Gha(k)"  = Tabla_rodal$Gha,
  "Vha(k)"  = Tabla_rodal$Vha,
  "V10(k)"  = Tabla_rodal$V10,
  check.names = FALSE
)

# B. Coeficientes del modelo
coef_export <- data.frame(
  "B0" = round(B0, 5),
  "B1" = round(B1, 5),
  check.names = FALSE
)

# C. Formateo de la tabla resumen de parámetros
parametros_resumen <- data.frame(
  "Parametro" = c(
    "Número de árboles por hectárea",
    "Área basal por hectárea",
    "Diametro prom aritmetico",
    "DCM",
    "Altura prom aritmetica",
    "Altura Lorey",
    "Volumen total",
    "Volumen V10"
  ),
  "Valor" = c(
    Parametros_rod$NhaT,
    Parametros_rod$GhaT,
    Parametros_rod$PromAritm,
    Parametros_rod$DCM,
    Parametros_rod$AltPromArit,
    Parametros_rod$AltPromLorey,
    Parametros_rod$VhaT,
    sum(Tabla_rodal$V10)
  ),
  check.names = FALSE
)

# D. Hoja de consistencia de datos de la muestra
hoja2 <- data.frame(
  NALU     = 23,
  NOMBRE   = "SANTIAGO",
  APELLIDO = "TIRONI",
  idRodal  = Muestra$idRodal,
  idUM     = Muestra$idUM,
  supUM    = Muestra$supUM,
  idArb    = Muestra$idArb,
  dap      = Muestra$dap,
  altura   = Muestra$altura
)


# 8. Generación del Archivo Excel de Salida 
wb <- createWorkbook()
addWorksheet(wb, "Resultados")
addWorksheet(wb, "Datos")

# Escribir Hoja 1: Resultados
writeData(wb, "Resultados", "A.- Tabla de rodal", startRow = 1, startCol = 1)
writeData(wb, "Resultados", tabla_export, startRow = 2, startCol = 1)

writeData(wb, "Resultados", "B.- Coeficientes modelo altura", startRow = 1, startCol = 8)
writeData(wb, "Resultados", coef_export, startRow = 2, startCol = 8)

writeData(wb, "Resultados", "C.- Parametros de rodal", startRow = 20, startCol = 1)
writeData(wb, "Resultados", parametros_resumen, startRow = 21, startCol = 1)

# Escribir Hoja 2: Datos
writeData(wb, "Datos", hoja2, startRow = 1, startCol = 1)

# Guardar libro
saveWorkbook(wb, "~/Downloads/SANTIAGO_TIRONI_Lab4ofi.xlsx", overwrite = TRUE)
