install.packages("readxl")
install.packages("forecast")
install.packages("ggplot2")
install.packages("dplyr")

# 1. Librerías y datos ----
library(readxl)
library(forecast)
library(ggplot2)
library(dplyr)

df <- read_excel("DatosAgroNet_limpio.xlsx")
# Supón que la columna de precios es COP_kg
df_total <- df
train_size <- floor(0.8 * nrow(df_total))
test_size <- nrow(df_total) - train_size
df_train <- df_total[1:train_size, ]
df_test <- df_total[(train_size+1):nrow(df_total), ]


# 4. Predicción y métricas ----
modelo_manual <- Arima(df$`COP/kg`, order = c(2, 1, 2), seasonal = list(order = c(0, 0, 1), period = 52))
fc_final <- forecast(modelo_manual, h = test_size)
pred <- fc_final$mean
conf_int <- fc_final$lower[,2:1]; # 95% por defecto

mae <- mean(abs(df_test$`COP/kg` - pred))
rmse <- sqrt(mean((df_test$`COP/kg` - pred)^2))
cat("MAE:", mae, "\nRMSE:", rmse, "\n")

# 5. Gráfica resultados ----
datos_plot <- data.frame(
  Fecha = c(df_total$Fecha),
  COP_kg = c(df_total$`COP/kg`)
)
pred_df <- data.frame(
  Fecha = df_test$Fecha,
  Prediccion = pred,
  Lower = conf_int[,1],
  Upper = conf_int[,2]
)
ggplot() +
  geom_line(data = datos_plot, aes(x = Fecha, y = COP_kg), color = "blue", size = 1) +
  geom_line(data = pred_df, aes(x = Fecha, y = Prediccion), color = "red", size = 1) +
  geom_ribbon(data = pred_df, aes(x = Fecha, ymin = Lower, ymax = Upper), fill="pink", alpha=0.3) +
  geom_vline(xintercept = datos_plot$Fecha[train_size], linetype="dashed") +
  labs(title = "Predicción SARIMA precio cacao con intervalos de confianza",
       x = "Fecha", y = "Precio cacao") +
  theme_minimal()
