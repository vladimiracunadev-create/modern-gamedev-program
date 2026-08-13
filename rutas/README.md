# 🧭 Rutas guiadas por rol

> [⬅️ Volver al programa](../README.md) · [📚 Índice completo](../classes/README.md) · [✅ Mi progreso](https://vladimiracunadev-create.github.io/modern-gamedev-program/autoevaluaciones/progreso.html)

El programa tiene **352 clases**; **no todas son para todos a la vez**. Estas rutas ordenan el recorrido según el rol al que apuntas: qué partes hacer, en qué orden y con qué laboratorio practicar.

Cada rol tiene una **guía de carrera completa** (qué es, día a día, qué necesitas saber, tu ruta en el curso, qué te contrata, salario orientativo, mitos y siguientes pasos). Haz clic en el nombre.

Todas asumen que **empiezas por la Parte 0** (fundamentos): es el cimiento común y no se salta. Y todas pasan por la **Parte 17** (capstone y portfolio): lo que te consigue el trabajo es un juego terminado, no un certificado.

> Leyenda: 📚 parte del curso · 🧪 laboratorio ejecutable · 🎯 hito.

---

## 🎮 Rutas de base (Partes 0–17)

Los siete recorridos clásicos. Se pueden empezar desde cero y cada uno termina en algo publicable.

| Rol | Partes | En una frase | Guía |
|---|---|---|---|
| **Programador de gameplay** | 0, 1, 2, 3, 5, 8, 14, 17 | Haces que el juego *se sienta* bien: el salto, el golpe, la cámara. | [📘 leer](gameplay.md) |
| **Programador gráfico / técnico** | 0, 1, 2, 4, 3, 14, 9, 17 | Escribes lo que la GPU ejecuta millones de veces por fotograma. | [📘 leer](grafico.md) |
| **Desarrollador indie (solo dev)** | 0, 1, 8, 9, 6, 10, 15, 16, 17 | Lo haces todo tú. La habilidad que más cuesta es **terminar**. | [📘 leer](indie.md) |
| **Desarrollador móvil / web** | 0, 1, 10, 11, 12, 14, 16, 17 | Alcance masivo y restricciones duras: batería, tamaño y dedos. | [📘 leer](movil-web.md) |
| **Programador de multijugador** | 0, 1, 2, 3, 7, 14, 15, 17 | Que dos personas con 80 ms de latencia vean la misma partida. | [📘 leer](multijugador.md) |
| **Diseñador de niveles / técnico** | 0, 1, 8, 2, 15, 10, 17 | Diseñas la experiencia **y** las herramientas que la construyen. | [📘 leer](diseno-niveles.md) |
| **Desarrollador XR (VR/AR)** | 0, 1, 2, 3, 14, 13, 6, 17 | Si baja de los fps objetivo, alguien se marea. De verdad. | [📘 leer](xr.md) |

## 🔧 Rutas de especialización (Partes 18–21)

Estas seis **empiezan donde terminan las anteriores**. Todas dan por supuesto que ya tienes un juego terminado: son la diferencia entre saber hacer un juego y saber sostener uno.

No las hagas por completismo. Cada una responde a un problema que reconocerás cuando lo tengas delante — un inventario que se corrompe, un backend que se cae, un NPC que regala espadas legendarias, un bucle que no baja de 40 ms.

| Rol | Partes | El problema que resuelve | Guía |
|---|---|---|---|
| **Programador de sistemas de gameplay** | 18 (+ 8, 16, 19) | Tus sistemas funcionan por separado y se rompen al combinarse. | [📘 leer](sistemas-gameplay.md) |
| **Ingeniero de backend y online** | 15, 19 (+ 18, 16) | Funciona en tu máquina. En producción hay red que falla a medias. | [📘 leer](backend-online.md) |
| **Desarrollador de IA para juegos** | 5, 18, 20 (+ 19) | Cuándo usar un behavior tree y cuándo un modelo. Casi siempre, lo primero. | [📘 leer](ia-juegos.md) |
| **Programador de motor / rendimiento** | 14, 21 (+ 4, 15) | El profiler dice 40 ms y no sabes por qué. | [📘 leer](motor-rendimiento.md) |
| **Arquitecto técnico de juegos** | 18, 19, 21, 16 (+ 20) | Decidir qué **no** se construye, y poder justificarlo. | [📘 leer](arquitecto-tecnico.md) |
| **Indie avanzado** | 18, 19, 21 (+ 20) | Publicaste. Ahora el problema es que aguante parches y jugadores. | [📘 leer](indie-avanzado.md) |

## 🔀 Cómo se encadenan

Las rutas no son compartimentos. Las de especialización tienen una entrada natural desde las de base:

```text
gameplay ──────────────► sistemas de gameplay ──┐
                                                ├─► arquitecto técnico
multijugador ──────────► backend y online ──────┘
                                                
gameplay + Parte 5 ────► IA para juegos
gráfico / XR ──────────► motor y rendimiento
indie ─────────────────► indie avanzado
```

## 💡 Cómo usar una ruta

- **Sigue el orden dentro de la ruta**, no el número de clase. Las rutas saltan partes a propósito.
- **Marca tu avance** en el [seguimiento de progreso](https://vladimiracunadev-create.github.io/modern-gamedev-program/autoevaluaciones/progreso.html).
- **Comprueba que lo dominas** con la [autoevaluación](https://vladimiracunadev-create.github.io/modern-gamedev-program/autoevaluaciones/quiz.html) de cada parte antes de pasar a la siguiente.
- **Haz los hitos 🎯**. Una parte "leída" no cuenta; una parte con algo construido, sí.
- **Los salarios de las guías son orientativos**, no promesas: dependen del país, del tamaño del estudio y del inglés más que de cualquier otra cosa.
