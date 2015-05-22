import sys
from itertools import permutations
from itertools import combinations

F2.<ww> = FiniteField(2)[]
F16.<alpha> = FiniteField(16, modulus= ww^4 + ww + 1, repr='int')

P2.<x,y,z> = ProjectiveSpace(F16,2)
X = Curve(x^2*z + x*z^2  - y^3 - y*z^2)

# The rational points of X except the point at infinity
rapp = filter(lambda t: t != [1,0,0], X.rational_points())

rap = []
for i in range(len(rapp)):
    rap.append([rapp[i][0], rapp[i][1], rapp[i][2]])

# siga auto
def sig_a(p):
    return [p[0] + p[2], p[1], p[2]]

siga = [sig_a]
i = 0
while (map(siga[i], rap) != rap):
    newf = lambda k: lambda p: sig_a(siga[k](p))
    siga.append(newf(i))
    i += 1

# sigb auto
def sig_b(p):
    return [p[0] + p[1]*alpha^14 + p[2]*alpha^7, p[1]*alpha^5 + p[2]*alpha^3, p[2]]

sigb = [sig_b]
i = 0
while (map(sigb[i], rap) != rap):
    newf = lambda k: lambda p: sig_b(sigb[k](p))
    sigb.append(newf(i))
    i += 1

# sigc auto
def sig_c(p):
    return [p[0] + p[1]*alpha^10 + p[2]*alpha^2, p[1] + p[2]*alpha^5, p[2]]

sigc = [sig_c]
i = 0
while (map(sigc[i], rap) != rap):
    newf = lambda k: lambda p: sig_c(sigc[k](p))
    sigc.append(newf(i))
    i += 1

# composition
def sig_abc(i,j,k):
    return lambda p: siga[i](sigb[j](sigc[k](p)))

# All of them
sigabc = []
for i in range(len(siga)):
    for j in range(len(sigb)):
        for k in range(len(sigc)):
            sigabc.append(sig_abc(i,j,k))

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

# Set a basis for L(13Q)
L12Q= [lambda x,y: alpha^0, #0
       lambda x,y: y,       #2
       lambda x,y: x,       #3
       lambda x,y: y^2,     #4
       lambda x,y: y*x,     #5
       lambda x,y: y^3,     #6
       lambda x,y: y^2*x,   #7
       lambda x,y: y^4,     #8
       lambda x,y: y^3*x,   #9
       lambda x,y: y^5,     #10
       lambda x,y: y^4*x,   #11
       lambda x,y: y^6]     #12



def try_small_codes_combis():
    for t in range(len(sigabc)):
        oaut = find_orbits(rap, sigabc[t]) # the orbits of the tth automorphism
        orbsize = len(oaut[0]) # We know that all automorphisms have orbits of only one size
        if (orbsize <= 2): # too small to be useful / too expensive to exhaust the combinations
            print "Skipping sigma_"+str(t)+", which has "+str(len(oaut))+" distinct orbits of size "+str(orbsize)
            sys.stdout.flush()
            continue
        else:
            for codelen in range(6,26,2):
                if (((codelen/2) % orbsize) == 0): # we can create a code of this even length that's aligned on orbits boundaries
                    numorbits = codelen/orbsize
                    all_combi = combinations(oaut,numorbits)
                    try:
                        while True:
                            this_oaut = next(all_combi)
                            aut_order = [] # the points we take, listed in the orbits order
                            for i in range(len(this_oaut)):
                                aut_order.extend(this_oaut[i])
                            matlines = []
                            for i in range(codelen/2):
                                matlines.append([])
                                for j in range(codelen):
                                    matlines[i].append(L12Q[i](aut_order[j][0], aut_order[j][1]))
                            Encodert = matrix(F16,matlines)
                            ReducedEncodert = Encodert.echelon_form()
                            RedRight = []
                            RedLeftt = []
                            for i in range(codelen/2):
                                RedRight.append([])
                                RedLeftt.append([])
                                for j in range(codelen/2):
                                    RedRight[i].append(ReducedEncodert[i][j])
                                    RedLeftt[i].append(ReducedEncodert[i][j+codelen/2])
                            RedR = matrix(RedRight)
                            RedL = matrix(RedLeftt)
                            if ((RedR.rank() == codelen/2) and (RedL.rank() == codelen/2)):
                                print "--------"
                                print RedR
                                print RedL
                                print "From orbits"
                                for zeta in range(len(this_oaut)):
                                    print this_oaut[zeta]
                                print "The cost of this matrix is "+matrixCost(RedL, codelen/2, codelen/2).str()
                                print "========"
                                sys.stdout.flush()
                    except StopIteration:
                        print "Finished processing sigma_"+str(t)+" of orbits of size "+str(orbsize)+", for codes of length "+str(codelen)
                        sys.stdout.flush()
            

try_small_codes_combis()
