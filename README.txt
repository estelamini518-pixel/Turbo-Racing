TURBO RACING: CARRERA EXTREMA
Proyecto Flutter preparado para compilar un APK Android con GitHub Actions.

CONTENIDO
- lib/main.dart: videojuego jugable de carreras con pista en perspectiva, coche, controles táctiles, obstáculos, puntos, cronómetro, nitro y pausa.
- pubspec.yaml: configuración Flutter.
- .github/workflows/build-apk.yml: compilación automática del APK.

PARA GENERAR EL APK EN GITHUB
1. Crea un repositorio llamado TURBO-RACING.
2. Sube el CONTENIDO de esta carpeta, no el ZIP.
3. Asegúrate de subir también la carpeta .github/workflows y el archivo build-apk.yml.
4. Entra en Actions y abre "Compilar Turbo Racing".
5. Espera a que termine con una marca verde.
6. Abre la ejecución y descarga el artefacto "Turbo-Racing-APK".
7. Extrae el ZIP del artefacto para obtener app-release.apk.

CONTROLES DEL JUEGO
- Flechas izquierda/derecha: cambiar de carril.
- Acelerar: aumentar velocidad.
- Frenar: reducir velocidad.
- NITRO: impulso temporal.
- Evita los obstáculos y recoge monedas para sumar puntos.
- Completa la carrera antes de quedarte sin tiempo.

NOTA
Es una primera versión jugable con efecto de perspectiva 2.5D dibujado en Flutter; no es un modelo 3D real de Unity. El APK se genera en GitHub Actions.
