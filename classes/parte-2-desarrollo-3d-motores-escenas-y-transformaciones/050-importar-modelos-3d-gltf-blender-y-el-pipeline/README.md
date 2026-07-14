# Clase 050 — Importar modelos 3D: glTF, Blender y el pipeline

> Parte: **2 — Desarrollo 3D: motores, escenas y transformaciones** · Fuente: *Documentación oficial de Godot 4 — Importing 3D scenes*
> ⏱️ Duración estimada: **60 min** · Nivel: **Intermedio**

---

## 🎯 Objetivo

Aprender a llevar modelos 3D creados fuera de Godot (en Blender u otras herramientas, o descargados de bibliotecas de assets) hasta tu escena, con el aspecto y la escala correctos. Entenderás por qué el formato glTF/GLB es el recomendado, cómo funciona el pipeline Blender → Godot, y cómo resolver los problemas clásicos: escala multiplicada por 100, ejes intercambiados, normales invertidas y texturas que no aparecen.

Al final habrás importado un modelo real, lo habrás instanciado sobre un suelo, corregido su escala y orientación, y sabrás leer el panel de importación para diagnosticar problemas.

## 📚 Resultados de aprendizaje

Al finalizar, el alumno podrá:

1. Explicar por qué glTF/GLB es el formato de intercambio recomendado para Godot 4.
2. Describir el pipeline de exportación desde Blender hacia Godot y la convención Y-up.
3. Importar un modelo a Godot e instanciarlo en una escena como hijo de un `Node3D`.
4. Corregir escala y orientación de un modelo importado desde el inspector de importación o por código.
5. Diagnosticar problemas comunes (escala x100, normales, texturas ausentes) usando el panel de importación.

## 🗺️ Temas

| # | Tema | Por qué importa |
|---|------|-----------------|
| 1 | Formatos 3D (glTF, GLB, .blend) | Elegir bien evita pérdida de datos y dolores de cabeza. |
| 2 | Por qué glTF/GLB | Es abierto, moderno y el mejor soportado por Godot 4. |
| 3 | Pipeline Blender → Godot | Saber el flujo evita reimportar mil veces. |
| 4 | Escala y ejes (Y-up) | Blender y Godot difieren; corregirlo es el paso más olvidado. |
| 5 | Importar como escena | Godot convierte el archivo en una escena instanciable. |
| 6 | Materiales importados | Entender qué se conserva y qué hay que rehacer. |
| 7 | Problemas comunes | Escala x100, normales y texturas rotas tienen solución conocida. |

## 📖 Definiciones y características

- **glTF**: formato abierto de Khronos para escenas 3D (geometría, materiales, animación). Clave: es el recomendado para Godot 4.
- **GLB**: variante binaria de glTF que empaqueta todo (malla, texturas) en un solo archivo. Clave: cómodo de mover, sin archivos sueltos.
- **.blend directo**: Godot puede importar archivos de Blender si Blender está instalado. Clave: útil, pero glTF es más portable.
- **Y-up**: Godot usa el eje Y hacia arriba; Blender usa Z-up. Clave: el importador ajusta ejes, pero conviene exportar con la opción correcta.
- **Importación como escena**: Godot genera un recurso de escena a partir del modelo. Clave: lo instancias como cualquier `.tscn`.
- **Escala de importación**: factor que multiplica el tamaño al importar. Clave: si el modelo aparece gigante o diminuto, se ajusta aquí.
- **Normales**: vectores de superficie que llegan con el modelo. Clave: si están invertidas, las caras se ven oscuras o transparentes.
- **Material importado**: material que Godot crea a partir del glTF. Clave: puedes extraerlo para editarlo o sustituirlo.

## 🧰 Herramientas y preparación

Necesitas Godot 4.x y, opcionalmente, Blender desde <https://www.blender.org/download/>. Consulta la guía oficial de importación de escenas 3D en <https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/index.html> y las especificaciones de glTF en <https://www.khronos.org/gltf/>. Para exportar desde Blender revisa <https://docs.blender.org/manual/en/latest/addons/import_export/scene_gltf2.html>. Puedes descargar un modelo glTF libre desde una biblioteca como <https://market.pmnd.rs/> o los ejemplos de Khronos en <https://github.com/KhronosGroup/glTF-Sample-Assets>. Crea un proyecto 3D nuevo.

## 🧪 Laboratorio guiado

Importaremos un modelo glTF, lo colocaremos sobre un suelo y corregiremos su escala y orientación por código como red de seguridad.

1. Consigue un archivo `.glb` o `.gltf` (por ejemplo, un modelo sencillo de los ejemplos de Khronos como el "Duck") y **copia el archivo dentro de la carpeta del proyecto** de Godot, en `res://modelos/`. Godot lo importará automáticamente al detectarlo.

2. Selecciona el archivo importado en el panel *Sistema de archivos* y abre la pestaña **Importar**. Ahí puedes ajustar la **escala** global y decidir cómo se generan materiales y colisiones. Si el modelo se ve enorme, prueba una escala de `0.01` (corrige el clásico x100). Pulsa **Reimportar**.

3. Crea la escena principal: un `Node3D` raíz `Nivel`, un suelo con `StaticBody3D` que contenga una `MeshInstance3D` con un `BoxMesh` plano y ancho (por ejemplo escala `Vector3(10, 0.2, 10)`), una `Camera3D` y una `DirectionalLight3D`.

4. Adjunta este script al nodo raíz. Instancia el modelo por código y ajusta escala y orientación para asegurar que quede bien apoyado y encarando la cámara:

```gdscript
extends Node3D

# Cargamos la escena importada del modelo glTF.
@export var modelo_escena: PackedScene = preload("res://modelos/pato.glb")

@export var escala_correccion: float = 1.0
@export var giro_y_grados: float = 180.0

func _ready() -> void:
	# Instanciamos el modelo importado.
	var modelo := modelo_escena.instantiate()
	add_child(modelo)

	# Nos aseguramos de que sea un Node3D para transformarlo.
	if modelo is Node3D:
		var m := modelo as Node3D
		# Corrección de escala por si el import quedó grande/pequeño.
		m.scale = Vector3.ONE * escala_correccion
		# Corrección de orientación (muchos modelos miran a +Z).
		m.rotation_degrees.y = giro_y_grados
		# Apoyamos el modelo sobre el suelo (y = 0).
		m.position = Vector3(0, 0, 0)
		print("Modelo instanciado. AABB usado para verificar apoyo.")

	# Colocamos la cámara para ver el modelo sobre el suelo.
	$Camera3D.position = Vector3(0, 2, 5)
	$Camera3D.look_at(Vector3(0, 0.5, 0), Vector3.UP)
```

5. Asegúrate de que la ruta del `preload` coincide con el nombre real de tu archivo. Ejecuta con **F6**. Deberías ver el modelo apoyado sobre el suelo, iluminado y encarando la cámara.

6. Diagnóstico práctico: si el modelo aparece gigante, ajusta `escala_correccion` (por ejemplo `0.01`) o corrige la escala en el panel Importar y reimporta. Si mira hacia el lado contrario, cambia `giro_y_grados`. Si se ve oscuro o con caras que desaparecen al girar la cámara, probablemente tenga normales invertidas: revísalo en Blender (Recalculate Normals Outside) y reexporta a glTF.

## ✍️ Ejercicios

1. Reimporta el mismo modelo con distinta escala en el panel Importar y compara con la corrección por código; decide cuál prefieres y por qué.
2. Instancia el modelo tres veces en posiciones distintas del suelo con un bucle `for`.
3. Extrae el material importado (haz clic derecho sobre el recurso importado y usa "Make Unique" / "Extract Materials") y cámbiale el `albedo_color`.
4. Añade una `CollisionShape3D` al modelo para que un objeto físico pueda apoyarse sobre él.
5. Rota el modelo lentamente en `_process` para inspeccionar todas sus caras y detectar normales invertidas.
6. Importa un segundo formato (por ejemplo un `.blend` directo si tienes Blender) y compara el resultado con el glTF.

## 📝 Reto verificable

Importa un modelo glTF externo, corrige su escala y orientación para que quede correctamente apoyado sobre un suelo, e instáncialo por código junto a al menos una copia adicional colocada en otra posición. **Criterio de aceptación**: al ejecutar, ambos modelos aparecen a escala razonable (ni gigantes ni microscópicos), apoyados sobre el suelo sin flotar ni hundirse, orientados de forma visible hacia la cámara, y el material se ve iluminado correctamente sin caras negras por normales invertidas.

## ⚠️ Errores comunes

| Síntoma / mensaje | Causa y cómo arreglar |
|-------------------|-----------------------|
| El modelo aparece gigantesco (x100) | Diferencia de unidades Blender/Godot. Ajusta la escala en el panel Importar (p. ej. 0.01) y reimporta. |
| El modelo está tumbado o mira al lado incorrecto | Diferencia Z-up vs Y-up. Exporta desde Blender con Y-up o corrige `rotation_degrees` en Godot. |
| Caras negras o que desaparecen al girar | Normales invertidas. En Blender usa "Recalculate Normals Outside" y reexporta. |
| Las texturas no aparecen | Rutas rotas o texturas no empaquetadas. Usa `.glb` (binario) que incluye todo, o coloca las texturas junto al `.gltf`. |
| `preload` falla: recurso no encontrado | La ruta no coincide con el archivo real. Verifica el nombre exacto en `res://modelos/`. |
| Cambios en el material no se guardan | El material es de solo lectura al venir importado. Extráelo ("Make Unique") antes de editarlo. |

## ❓ Preguntas frecuentes

**❓ ¿Por qué se recomienda glTF y no FBX u OBJ?** glTF es abierto, moderno y transporta geometría, materiales PBR y animación de forma estandarizada. OBJ no lleva animación ni materiales PBR completos, y FBX es propietario y con soporte más frágil.

**❓ ¿Puedo importar archivos .blend directamente?** Sí, si tienes Blender instalado y configurado en Godot. Es cómodo durante el desarrollo, pero para entregar el proyecto conviene exportar a glTF por portabilidad.

**❓ ¿Debo corregir la escala en el import o por código?** Preferentemente en el panel Importar, para que el modelo llegue ya correcto a todas las escenas. La corrección por código es una red de seguridad puntual.

**❓ ¿Qué hago si el modelo trae varios objetos y materiales?** Godot lo importa como una escena con su jerarquía. Puedes instanciarla completa, o abrirla y extraer materiales y submallas individuales para editarlos.

## 🔗 Referencias

- Godot Docs — Importing 3D scenes: <https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/index.html>
- Khronos — glTF Overview: <https://www.khronos.org/gltf/>
- Blender Manual — glTF 2.0 exporter: <https://docs.blender.org/manual/en/latest/addons/import_export/scene_gltf2.html>
- Khronos glTF Sample Assets (modelos de prueba): <https://github.com/KhronosGroup/glTF-Sample-Assets>

## ➡️ Siguiente clase

[Clase 051 - Cámaras 3D: perspectiva, FOV y Camera3D](../051-camaras-3d-perspectiva-fov-y-camera3d/README.md)
