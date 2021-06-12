from os import path

DESTINO = f'C:/Projetos/abcs'

if path.exists(DESTINO) == False:
    print('Caminho DESTINO não existe!')

