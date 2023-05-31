import threading
import time
import concurrent.futures


def threadFunction(x,y):
	time.sleep(2)
	print("thread:     ",x**2,y)
	return x**2

returnVal = -1
executor = concurrent.futures.ThreadPoolExecutor()

for i in range(10):
	# x = threading.Thread(target=threadFunction,args=(i,),daemon=True)
	# x.start()
			
	future = executor.submit(threadFunction,i,i*2)

	print("Waiting...")
	time.sleep(1)
	print("main:",i,"returned: ",returnVal)

	returnVal = future.result()
