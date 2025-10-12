install.packages(c("fitdistrplus", "ggplot2", "readxl"))

library(fitdistrplus)
library(ggplot2)
library(readxl)

# Importar datos
datos <- read_excel("Produccion.xlsx", sheet="Proporcion")

# Verificar
head(datos)
summary(datos$MARZ)


# VISUALIZACION DE LOS DATOS ------------------------------
ggplot(datos, aes(x = DIC)) +
  geom_histogram(aes(y = ..density..), bins = 10, fill = "lightblue", color = "black") +
  geom_density(color = "red", linewidth = 1) +
  labs(title = "Distribución de la proporción mensual de producción")


# AJUSTE --------------------------------------------------
x <- datos$DIC

# Normal
ajuste_norm <- fitdist(x, "norm")

# Exponencial
ajuste_exp <- fitdist(x, "exp")

# Beta (solo si 0 < x < 1)
ajuste_beta <- fitdist(x, "beta", start = list(shape1 = 2, shape2 = 2))

# Uniforme
ajuste_unif <- fitdist(x, "unif")

# PARAMETROS
ajuste_norm
ajuste_exp
ajuste_beta
ajuste_unif

resumen <- data.frame(
  Distribucion = c("Normal", "Exponencial", "Beta", "Uniforme"),
  AIC = c(ajuste_norm$aic, ajuste_exp$aic, ajuste_beta$aic, ajuste_unif$aic),
  BIC = c(ajuste_norm$bic, ajuste_exp$bic, ajuste_beta$bic, ajuste_unif$bic)
)
print(resumen)

# PRUEBAS DE AJUSTE KOLMOGOROV-SMIRNOV --------------------
# Normal
ks.test(x, "pnorm", mean = mean(x), sd = sd(x))

# Exponencial
ks.test(x, "pexp", rate = 1/mean(x))

# Beta
param_beta <- coef(ajuste_beta)
ks.test(x, "pbeta", shape1 = param_beta["shape1"], shape2 = param_beta["shape2"])

# Uniforme
ks.test(x, "punif", min = min(x), max = max(x))

# VISUALIZACION COMPARATIVA -------------------------------
par(mfrow = c(2, 2))
plot(ajuste_norm)
plot(ajuste_exp)
plot(ajuste_beta)
plot(ajuste_unif)



