import pandas as pd
import numpy as np
import itertools
import statsmodels.api as sm
import matplotlib.pyplot as plt

# === 1. Preparar los datos ===
df = pd.read_excel("DatosAgroNet_limpio.xlsx")

# === 2. Definir rangos de parámetros ===
p = d = q = range(0, 3)   # probar 0, 1 o 2
pdq = list(itertools.product(p, d, q))

P = D = Q = range(0, 2)   # probar 0, 1 o 2
seasonal_pdq = [(x[0], x[1], x[2], 26) for x in itertools.product(P, D, Q)]

# === 3. Grid search SARIMA ===
results_aic = []

for param in pdq:
    for param_seasonal in seasonal_pdq:
        try:
            mod = sm.tsa.statespace.SARIMAX(df['COP/kg'],
                                            order=param,
                                            seasonal_order=param_seasonal,
                                            enforce_stationarity=False,
                                            enforce_invertibility=False)
            res = mod.fit(disp=False)
            results_aic.append((param, param_seasonal, res.aic))
        except Exception as e:
            print(f"Falló SARIMA{param}x{param_seasonal} - Error: {e}")

# === 4. Ordenar resultados por AIC ===
results_table = pd.DataFrame(results_aic, columns=['order','seasonal_order','AIC'])
results_table = results_table.sort_values('AIC').reset_index(drop=True)
print(results_table.head(10))  # mostrar los 10 mejores

# === 5. Ajustar el mejor modelo ===
best_order = results_table.iloc[0]['order']
best_seasonal = results_table.iloc[0]['seasonal_order']

print(f"Mejor modelo encontrado: SARIMA{best_order}x{best_seasonal} - AIC:{results_table.iloc[0]['AIC']}")

mod = sm.tsa.statespace.SARIMAX(df['COP/kg'],
                                order=best_order,
                                seasonal_order=best_seasonal,
                                enforce_stationarity=False,
                                enforce_invertibility=False)
res = mod.fit(disp=False)

print(res.summary())

# === 6. Forecast ===
forecast = res.get_forecast(steps=52)
pred_mean = forecast.predicted_mean
conf_int = forecast.conf_int()

plt.figure(figsize=(12,6))
plt.plot(df.index, df['COP/kg'], label="Histórico")
plt.plot(pred_mean.index, pred_mean, label="Pronóstico", color='red')
plt.fill_between(pred_mean.index, conf_int.iloc[:,0], conf_int.iloc[:,1],
                 color='pink', alpha=0.3, label="Intervalo confianza")
plt.legend()
plt.title("Forecast SARIMA manual (52 semanas)")
plt.show()
