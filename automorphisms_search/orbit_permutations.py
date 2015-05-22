import sys
from itertools import permutations


F2.<ww> = FiniteField(2)[]
F16.<alpha> = FiniteField(16, modulus= ww^4 + ww + 1, repr='int')

P2.<x,y,z> = ProjectiveSpace(F16,2)
X = Curve(x^5 - y^2*z^3 - y*z^4)

# The rational points of X except the point at infinity
rap = filter(lambda t: t != [0,1,0], X.rational_points())

# Set a basis for L(17Q)
L17QB1= [lambda x,y: alpha^0,
         lambda x,y: x,
         lambda x,y: x^2,
         lambda x,y: x^3,
         lambda x,y: x^4,
         lambda x,y: x^5,
         lambda x,y: x^6,
         lambda x,y: x^7,
         lambda x,y: x^8,
         lambda x,y: y,
         lambda x,y: x*y,
         lambda x,y: x^2*y,
         lambda x,y: x^3*y,
         lambda x,y: x^4*y,
         lambda x,y: x^5*y,
         lambda x,y: x^6*y]

# One set of automorphisms
# First needs to be parametered by a point of the curve
# Then takes a point as list [x, y, z] and returns sig_a,b(x,y)
def sig_p(a,b):
    return lambda p: [p[0] + a, p[1] + a^8*p[0]^2 + a^4*p[0] + b^4, p[2]]

# A list of all the above automorphisms parametered with the points on the curve (except the point at infinity)
sigs = []
for i in range(len(rap)):
    sigs.append(sig_p(rap[i][0],rap[i][1]))

# Another family, with fifth roots of unity on x
def sig_z(z):
    return lambda p: [p[0]*z, p[1], p[2]]

# A list of all the above automorphisms parametered 5th roots of unity (the brutal way)
sigz = []
for i in range(15):
    if alpha^(5*i) == alpha^0:
        sigz.append(sig_z(alpha^i))

# Another family, with fifth roots of unity on x
def sig_z(z):
    return lambda p: [p[0]*z, p[1], p[2]]

# The Froebenius auto or identity
def sig_f(oui):
    if (oui==1):
        return lambda p: [p[0]^2, p[1]^2, p[2]]
    if (oui==0):
        return lambda p: p

sigf = [sig_f(0), sig_f(1)]

# Composition of the two
def sig_sz(i,j):
    return lambda p: sigz[i](sigs[j](p))

sigs2 = []
for i in range(len(sigz)):
    for j in range(len(sigs)):
        sigs2.append(sig_sz(i,j))

# Composition of the three
def sig_szf(i,j,k):
    return lambda p: sigf[i](sigz[j](sigs[k](p)))

sigs3 = []
for i in range(2):
    for j in range(len(sigz)):
        for k in range(len(sigs)):
            sigs3.append(sig_szf(i,j,k))

# Takes a list of points and a permutation
# returns the list of orbits of perm on this list
def find_orbits(pl, perm):
    pointlist = []
    pointlist.extend(pl)
    decompo = []
    while pointlist != []:
        point   = [pointlist[0][0], pointlist[0][1], pointlist[0][2]]
        pointit = point
        subdecompo = []
        subdecompo.append(point)
        pointlist.remove(point)
        pointit = perm(point)
        while pointit != point:
            subdecompo.append(pointit)
            pointlist.remove(pointit)
            pointit = perm(pointit)
        decompo.append(subdecompo)
    return decompo

def matrixCost(m, hd, vd):
  CV = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  KO = [0, alpha^0]
  for i in range(hd):
    tCV = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    for j in range(vd):
      tCV[int(m[i][j].int_repr())] += 1
      if (KO.count(m[i][j]) == 0):
          KO.append(m[i][j])
    for k in range(15):
      CV[k + 1] = max(CV[k + 1], tCV[k + 1])
  cost = 0;
  for k in range(15):
    cost += CV[k + 1]
  cost += (len(KO) - 2)
  return cost

def try_all_orbit_perms():
	for t in range(len(sigs2)):
	    oaut = find_orbits(rap, sigs2[t]) # the orbits of the tth automorphism
	    if (len(oaut) < 9):
	        all_oauts = permutations(oaut)
	        try:
	            while True:
	                this_oaut = next(all_oauts)
	                sum_first_orbs = 0
	                orbi = 0
	                while (sum_first_orbs < 16):
	                    sum_first_orbs += len(this_oaut[orbi])
	                    orbi += 1
	                if (sum_first_orbs > 16): # we can't get a 16/16 split with these orbits listed in this way
	                    continue
	                else:
	                    aut_order = []
	                    for i in range(len(this_oaut)):
	                        aut_order.extend(this_oaut[i])
	                    matlines = []
	                    for i in range(16):
	                        matlines.append([])
	                        for j in range(32):
	                            matlines[i].append(L17QB1[i](aut_order[j][0], aut_order[j][1]))
	                    Encodert = matrix(F16,matlines)
	                    ReducedEncodert = Encodert.echelon_form()
	                    RedRight = []
	                    RedLeftt = []
	                    for i in range(16):
	                        RedRight.append([])
	                        RedLeftt.append([])
	                        for j in range(16):
	                           RedRight[i].append(ReducedEncodert[i][j])
	                           RedLeftt[i].append(ReducedEncodert[i][j+16])
	                    RedR = matrix(RedRight)
	                    RedL = matrix(RedLeftt)
	                    if ((RedR.rank() == 16) and (RedL.rank() == 16)):
	                        print RedR
	                        print RedL
	                        print matrixCost(RedL, 16, 16)
	                        sys.stdout.flush()
	        except StopIteration:
	            print "Finished processing sigma_"+str(t)
	            sys.stdout.flush()
	    else:
	        print "Skipping sigma_"+str(t)+", which has "+str(len(oaut))+" distinct orbits"
	        sys.stdout.flush()

def try_all_orbit_perms2():
	for t in range(len(sigs3)):
	    oaut = find_orbits(rap, sigs3[t]) # the orbits of the tth automorphism
	    if (len(oaut) == 4): # mostly the 8888 are targeted
	        all_oauts = permutations(oaut)
	        try:
	            while True:
	                this_oaut = next(all_oauts)
	                sum_first_orbs = 0
	                orbi = 0
	                while (sum_first_orbs < 16):
	                    sum_first_orbs += len(this_oaut[orbi])
	                    orbi += 1
	                if (sum_first_orbs > 16): # we can't get a 16/16 split with these orbits listed in this way
	                    continue
	                else:
	                    aut_order = []
	                    for i in range(len(this_oaut)):
	                        aut_order.extend(this_oaut[i])
	                    matlines = []
	                    for i in range(16):
	                        matlines.append([])
	                        for j in range(32):
	                            matlines[i].append(L17QB1[i](aut_order[j][0], aut_order[j][1]))
	                    Encodert = matrix(F16,matlines)
	                    ReducedEncodert = Encodert.echelon_form()
	                    RedRight = []
	                    RedLeftt = []
	                    for i in range(16):
	                        RedRight.append([])
	                        RedLeftt.append([])
	                        for j in range(16):
	                           RedRight[i].append(ReducedEncodert[i][j])
	                           RedLeftt[i].append(ReducedEncodert[i][j+16])
	                    RedR = matrix(RedRight)
	                    RedL = matrix(RedLeftt)
	                    if ((RedR.rank() == 16) and (RedL.rank() == 16)):
	                        print RedR
	                        print RedL
	                        print "The cost of this matrix is "+matrixCost(RedL, 16, 16).str()
	                        print "================================================="
	                        sys.stdout.flush()
	        except StopIteration:
	            print "Finished processing sigma_"+str(t)
	            sys.stdout.flush()
	    else:
	        print "Skipping sigma_"+str(t)+", which has "+str(len(oaut))+" distinct orbits"
	        sys.stdout.flush()


#try_all_orbit_perms()
try_all_orbit_perms2()
