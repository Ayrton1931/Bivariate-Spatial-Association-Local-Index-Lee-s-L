**@autor: Ayrton Dextre
** Fecha: 19/11/2020
** Descripción: Este do-file contiene un algoritmo para estimar la significacia de los estadisticos L de Lee's locales.
**
** Descripción del Algoritmo: Para este caso particular, 
**							  la permutacion se realiza sobre el vector que le pertenece a la observación 
**							  Ello significa que la cantidad de vecinos permanece igual, pero sus posiciones cambian. 
**							  Solo se mantiene la posicion de la observación.

** Este codigo requiere la especificación de 5 variables: (1) Numero de permutaciones, (2 y 3) Vector de labores ambas variables, (4) especificacion de la matriz de pesos (no estandarizada), y (5) un identificador.

**** Import matrix to MATA
mata: identificador = st_matrix("identificador")
mata: N_P = st_matrix("n_p")
mata: X = st_matrix("Z_x")
mata: Y = st_matrix("Z_y")
mata: V   = st_matrix("V")
mata: N = rows(V)
mata: v1 = J(N,1,1)
**** Standardize varibles
mata: mean_X = mean(X)
mata: mean_Y = mean(Y)
mata: std_X	 = ((1/(N-1))*trace((X - v1*mean_X)*(X - v1*mean_X)'))^(1/2)
mata: std_Y  = ((1/(N-1))*trace((Y - v1*mean_Y)*(Y - v1*mean_Y)'))^(1/2)
mata: Z_x    = (X - v1*mean_X)*(1/std_X)
mata: Z_y    = (Y - v1*mean_Y)*(1/std_Y)

****
**** Change diagonal of V matrix: zero diagonal to 1's.

mata:
V_1 = V
for(i=1; i<=N; i++){
V_1[i,i] = 1
}
end
mata: V = V_1

python: 
from sfi import Mata
import pandas as pd
import numpy as np
from scipy import stats
import matplotlib.pyplot as plt
import os
end

python: z_x = np.matrix( Mata.get('Z_x') ) 
python: z_y = np.matrix( Mata.get('Z_y') ) 
python: v1 = np.matrix(Mata.get('v1'))
python: a = np.matrix( Mata.get('V') )
python: N = np.matrix(Mata.get('N')) 
python: N = int( np.asscalar( N ) )
python: num_permunt =  np.matrix( Mata.get('N_P') )
python: num_permunt = int(np.asscalar( num_permunt  ) )
python: identificador = np.matrix(Mata.get('identificador'))
python: identificador = int( np.asscalar(identificador) )

python:
def Permut(X, xx):
	vlarge = X.shape
	b = X
	list_index=[]
	list_oindex=[]
	for i in range(0, vlarge[1]):
		if int(b[0,i]) == 1:
			list_index.append(i)
		else:
			list_oindex.append(i)	
	list_index.remove(xx)
	if len(list_index)==0:
		pseudo_vector=b
		return(pseudo_vector)
	else:
		random_i = int(np.random.uniform(low=1, high=len(list_index)+1 , size=None))
		list_index_1C=[]
		list_index_2C=[]
		for ii in range(1, random_i+1):	
			if ii==1:
				random_i1v = int(np.random.uniform(low=0, high=len(list_index) , size=None))
				list_index_1C.append(random_i1v)
				random_i2v = int(np.random.uniform(low=0, high=len(list_oindex) , size=None))
				list_index_2C.append(random_i2v)		
			else:
				rand_1=random_i1v
				while rand_1 in list_index_1C:
					rand_1 = int(np.random.uniform(low=0, high=len(list_index), size=None))
				list_index_1C.append(rand_1)		
				rand_2= random_i2v
				while rand_2 in list_index_2C :
					rand_2 = int(np.random.uniform(low=0, high=len(list_oindex) , size=None)) 
				list_index_2C.append(rand_2)	
		vector_list = b.tolist()
		for jj in range(0, len(list_index_1C)):
			ind1 = list_index_1C[jj]	
			ind2 = list_index_2C[jj]	
			ind11 = list_index[ind1]
			ind22 = list_oindex[ind2]	
			vector_list[0][ind11] = 0
			vector_list[0][ind22] = 1	
		pseudo_vector= vector_list[0]
		return(pseudo_vector)
	print("End of Permutation.....")
end

python:
list_bbi = []
list_percent=[]
for j in range(0, N):
	list_bb=[]
	for i in range(0,num_permunt):
		print("Permutation" + " " + str(i) + " of place " + str(j)  )
		vec = Permut(a[j,], j)	
		bb_i = (vec*z_x)*(vec*z_y)/((vec*v1)*(vec*v1)) 
		list_bb.append(np.asscalar(bb_i))
	bb_stat = (a[j,]*z_x)*(a[j,]*z_y)/((a[j,]*v1)*(a[j,]*v1))
	bb_stat = np.asscalar(bb_stat)
	bb_array = np.array( list_bb )
	z = (bb_stat - bb_array.mean())/bb_array.std()
	b_statistics = [bb_stat, bb_array.mean(), bb_array.std(), z ]
	list_bbi.append(b_statistics)
	percent = stats.percentileofscore(bb_array, bb_stat, 'weak')
	list_percent.append(percent)
end
python: Resultados = pd.concat( [pd.DataFrame( list_bbi ), pd.DataFrame( list_percent ) ] , axis=1 )
python: Resultados.columns=["stat", "E", "std", "z", "percentil"]
python: Resultados["identificador"] = identificador