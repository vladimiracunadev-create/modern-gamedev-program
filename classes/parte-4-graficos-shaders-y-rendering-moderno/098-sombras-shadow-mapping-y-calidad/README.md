# Clase 098 — Sombras: shadow mapping y calidad

> Parte: **4 — Gráficos, shaders y rendering moderno** · Fuente: *Godot Docs — Lights and shadows / DirectionalLight3D shadow settings*
> ⏱️ Duración estimada: **55 min** · Nivel: **Avanzado**

---

## 🎯 Objetivo

Entender cómo Godot 4 genera sombras con **shadow mapping** (un mapa de profundidad renderizado desde el punto de vista de la luz) y aprender a diagnosticar y corregir los dos artefactos clásicos —**shadow acne** y **peter-panning**— ajustando *bias*, *normal bias*, resolución del mapa y **cascadas (CSM)** para sombras direccionales.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar el algoritmo de shadow mapping en dos pasadas (mapa de profundidad + comparación).
2. Identificar visualmente shadow acne y peter-panning y nombrar su causa.
3. Ajustar *Bias* y *Normal Bias* para eliminar acné sin introducir peter-panning.
4. Configurar cascadas (CSM) y su distribución (split, fade) en una `DirectionalLight3D`.
5. Balancear calidad de sombra contra coste de GPU eligiendo resolución y modo de filtrado.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Mapa de profundidad desde la luz | Es la base de toda sombra en tiempo real |
| 2 | Comparación de profundidad (depth test) | Decide si un fragmento está en sombra |
| 3 | Shadow acne (auto-sombreado) | El artefacto más común al activar sombras |
| 4 | Peter-panning (sombra despegada) | Efecto secundario de un bias excesivo |
| 5 | PCF y suavizado de bordes | Convierte bordes dentados en bordes suaves |
| 6 | Cascadas (CSM) direccionales | Reparte resolución según distancia a cámara |
| 7 | Resolución del shadow atlas | Define nitidez y consumo de VRAM |
| 8 | Coste y presupuesto de sombras | Sombras son caras: hay que medir |

## 📖 Definiciones y características

- **Shadow map**: textura de profundidad que guarda, por cada téxel, la distancia del objeto más cercano a la luz. Un fragmento está en sombra si su profundidad supera la almacenada.
- **Shadow acne**: patrón de rayas oscuras sobre superficies iluminadas causado por precisión finita del mapa: un téxel cubre varios fragmentos y algunos quedan "detrás" de sí mismos.
- **Bias**: desplazamiento que aleja la comparación de profundidad para evitar el auto-sombreado. Demasiado bias produce peter-panning.
- **Normal bias**: desplaza el punto de muestreo a lo largo de la normal; corrige acné en superficies inclinadas con menos peter-panning que el bias plano.
- **Peter-panning**: la sombra se separa de la base del objeto, que parece "flotar", porque el bias empujó el contacto.
- **PCF (Percentage Closer Filtering)**: promedia varias muestras vecinas del mapa para suavizar el borde de la sombra.
- **CSM (Cascaded Shadow Maps)**: divide el frustum en tramos (cascadas) con mapas distintos; los tramos cercanos reciben más resolución.
- **Directional shadow mode**: en Godot, `Orthogonal`, `PSSM 2 Splits` o `PSSM 4 Splits` controlan cuántas cascadas usa la luz direccional.

## 🧰 Herramientas y preparación

Necesitas Godot 4.x con el renderizador **Forward+** o **Mobile** (el shadow mapping de alta calidad y las cascadas están más completos en Forward+). Crea una escena con un `WorldEnvironment`, un plano grande como suelo, varias cajas y una `DirectionalLight3D`. Activa las sombras en la luz (`Shadow > Enabled`). Ten a mano el inspector de la luz y del `Project Settings > Rendering > Lights and Shadows`, donde se define el tamaño del atlas.

- Documentación de sombras: <https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html>
- Ajustes de calidad de sombra: <https://docs.godotengine.org/en/stable/tutorials/3d/using_transform_feedback.html> (referencia general de rendering)

## 🧪 Laboratorio guiado

Vamos a configurar sombras de calidad y a provocar y corregir los artefactos para verlos con nuestros ojos.

**Paso 1 — Escena base.** Crea `Node3D` raíz con un suelo (`MeshInstance3D` + `PlaneMesh` de 40×40), tres o cuatro `BoxMesh` apoyadas encima y una `DirectionalLight3D` inclinada (rotación X ≈ -45°).

**Paso 2 — Activar sombras.** En la `DirectionalLight3D`: `Shadow > Enabled = On`. Muy probablemente aparezcan rayas oscuras: eso es **shadow acne**.

**Paso 3 — Provocar peter-panning.** Sube `Shadow > Bias` a un valor exagerado (por ejemplo `0.5`). El acné desaparece pero las sombras se despegan de la base de las cajas: **peter-panning**.

**Paso 4 — Encontrar el equilibrio.** Baja `Bias` hasta ~`0.03`–`0.06` y sube `Normal Bias` a ~`1.0`–`2.0`. El normal bias corrige el acné en caras inclinadas sin despegar la sombra.

**Paso 5 — Cascadas.** En `Directional Shadow > Mode` elige `PSSM 4 Splits`. Ajusta `Split 1/2/3` para repartir resolución (valores por defecto suelen ir bien) y usa `Blend Splits = On` para suavizar la transición entre cascadas.

**Paso 6 — Resolución del atlas.** En `Project Settings > Rendering > Lights and Shadows > Directional Shadow > Size`, prueba `2048` frente a `4096`. Observa cómo el borde se vuelve más nítido a mayor tamaño y anota el coste.

**Paso 7 — Script para alternar calidad en runtime** y comparar rápido:

```gdscript
extends DirectionalLight3D

# Alterna entre un preset "rápido" y uno "de calidad" con la tecla Espacio.
var _calidad := false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_calidad = not _calidad
		if _calidad:
			shadow_bias = 0.04
			shadow_normal_bias = 1.5
			directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		else:
			shadow_bias = 0.5           # exagerado: verás peter-panning
			shadow_normal_bias = 0.0
			directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		print("Calidad:", _calidad, " bias:", shadow_bias)
```

Al pulsar Espacio verás alternar el artefacto y la corrección: eso es lo **visible** de esta clase.

## ✍️ Ejercicios

1. Con `Bias = 0` describe por escrito el patrón de acné y en qué caras aparece más.
2. Encuentra el `Bias` mínimo que elimina el acné en una esfera; anota el valor.
3. Sube solo `Normal Bias` (con `Bias` bajo) y explica por qué reduce el acné en rampas.
4. Compara `PSSM 2 Splits` vs `4 Splits` a 30 m de cámara: ¿dónde se nota más?
5. Mide FPS con atlas `2048` y `4096` en la misma escena y calcula el % de diferencia.
6. Añade una `OmniLight3D` con sombra y observa que usa un cubemap, no cascadas.

## 📝 Reto verificable

Crea una escena con suelo, al menos cinco objetos y una `DirectionalLight3D` con sombras configuradas de forma que **no** haya acné visible **ni** peter-panning perceptible en el contacto de los objetos con el suelo, usando `PSSM 4 Splits`.

**Criterio de aceptación**: en una captura cenital y otra a ras de suelo no se aprecian rayas de auto-sombreado ni separación entre el objeto y su sombra; los valores de `Bias`, `Normal Bias`, `Mode` y `Size` quedan documentados en un comentario del script de la escena.

## ⚠️ Errores comunes

| Síntoma | Causa y arreglo |
|---------|-----------------|
| Rayas oscuras sobre lo iluminado | Shadow acne por bias insuficiente; sube `Bias` y sobre todo `Normal Bias` |
| La sombra flota, el objeto parece despegado | Peter-panning por bias excesivo; baja `Bias` y compensa con `Normal Bias` |
| Sombras pixeladas/dentadas | Atlas pequeño; sube `Directional Shadow > Size` o activa filtrado suave |
| Sombras desaparecen a lo lejos | `Max Distance` de la sombra direccional demasiado corto; auméntalo |
| Costura visible entre cascadas | Transición dura; activa `Blend Splits` y ajusta los splits |
| FPS se hunde al activar sombras | Atlas enorme o muchas luces con sombra; reduce `Size` o limita luces sombreadas |

## ❓ Preguntas frecuentes

**¿Por qué el acné forma rayas y no manchas?** Porque cada téxel del mapa cubre una franja de la superficie; dentro de esa franja la profundidad interpolada oscila por encima y por debajo del valor almacenado.

**¿Normal bias reemplaza a bias?** No; se complementan. El bias plano corrige caras frontales a la luz y el normal bias corrige caras inclinadas. Se ajustan juntos.

**¿Más cascadas siempre es mejor?** No: 4 splits dan más nitidez cercana pero cuestan más y pueden mostrar costuras. Usa las que tu escena necesite.

**¿Las sombras de `OmniLight3D` usan cascadas?** No; las luces puntuales proyectan a un cubemap y las spot a un solo mapa. Las cascadas son exclusivas de la luz direccional.

## 🔗 Referencias

- Godot — Lights and shadows: <https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html>
- Godot — DirectionalLight3D (clase): <https://docs.godotengine.org/en/stable/classes/class_directionallight3d.html>
- Godot — Rendering settings (Lights and Shadows): <https://docs.godotengine.org/en/stable/classes/class_projectsettings.html>

## ⬅️ Clase anterior

[Clase 097 - Efectos: bloom, vignette, aberración cromática y CRT](../097-efectos-bloom-vignette-aberracion-cromatica-y-crt/README.md)

## ➡️ Siguiente clase

[Clase 099 - Transparencia, blending y orden de dibujado](../099-transparencia-blending-y-orden-de-dibujado/README.md)
