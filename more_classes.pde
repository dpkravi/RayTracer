// Bounding Box primitive class
class Box extends RenderObj {
  
  PVector minPt;
  PVector maxPt;

  Box() {
      super(boxType);
      minPt = new PVector(0,0,0);
      maxPt = new PVector(0,0,0);
  }

  /**< setBounds */
   void setBounds(PVector min, PVector max ) {
     minPt.x = min.x; 
     minPt.y = min.y; 
     minPt.z = min.z; 
     maxPt.x = max.x; 
     maxPt.y = max.y; 
     maxPt.z = max.z; 
   }
   
   void set( float xmin, float ymin, float zmin, float xmax, float ymax, float zmax, Material mat ) {
     minPt.x = xmin; 
     minPt.y = ymin; 
     minPt.z = zmin; 
     maxPt.x = xmax; 
     maxPt.y = ymax; 
     maxPt.z = zmax; 
     material = mat;
   }

  void copyData( Box box ) {

     minPt.x = box.minPt.x; 
     minPt.y = box.minPt.y; 
     minPt.z = box.minPt.z; 
     maxPt.x = box.maxPt.x; 
     maxPt.y = box.maxPt.y; 
     maxPt.z = box.maxPt.z; 
     
     material = box.material;
  }
  
  RayCollInfo intersection(Ray r) {

     float t1, t2, near, far;
     near = -1000;
     far = 1000;
     PVector nx = new PVector(0, 0, 0);
     PVector ny = new PVector(0, 0, 0);
     PVector nz = new PVector(0, 0, 0);
  
     PVector n = new PVector(0, 0, 0);
  
     float temp;
  
     // Plane in X    
     if (r.direction.x == 0) {
       if (r.origin.x < minPt.x || r.origin.x > maxPt.x) {
         return new RayCollInfo(false);
       }
     }
  
     t1 = (minPt.x - r.origin.x) / r.direction.x;
     t2 = (maxPt.x - r.origin.x) / r.direction.x;
  
     nx.x = -1;
     nx.y = 0;
     nx.z = 0;
  
     if (t1 > t2) {
       temp = t2;
       t2 = t1;
       t1 = temp;
       nx.x = +1;
       nx.y = 0;
       nx.z = 0;
     }
     if (t1 > near) {
       near = t1;
       n = nx;
     }
     if (t2 < far) {
       far = t2;
     }
     if (near > far) {
       return new RayCollInfo(false);
     }
     if (far < 0) {
       return new RayCollInfo(false);
     }
  
     // Plane in Y
     if (r.direction.y == 0) {
       if (r.origin.y < minPt.y || r.origin.y > maxPt.y) {
         return new RayCollInfo(false);
       } 
     }
  
     t1 = (minPt.y - r.origin.y) / r.direction.y;
     t2 = (maxPt.y - r.origin.y) / r.direction.y;
  
     ny.x = 0;
     ny.y = -1;
     ny.z = 0;
  
     if (t1 > t2) {
       temp = t2;
       t2 = t1;
       t1 = temp;
       ny.x = 0;
       ny.y = +1;
       ny.z = 0;
     }
     if (t1 > near) {
       near = t1;
       n = ny;
     }
     if (t2 < far) {
       far = t2;
     }
     if (near > far) {
       return new RayCollInfo(false);
     }
     if (far < 0) {
       return new RayCollInfo(false);
     }
  
     // Plane in Z
     if (r.direction.z == 0) {
       if (r.origin.z < minPt.z || r.origin.z > maxPt.z) {
         return new RayCollInfo(false);
       }
     }
  
     t1 = (minPt.z - r.origin.z) / r.direction.z;
     t2 = (maxPt.z - r.origin.z) / r.direction.z;
  
     nz.x = 0;
     nz.y = 0;
     nz.z = -1;
  
     if (t1 > t2) {
       temp = t2;
       t2 = t1;
       t1 = temp;
       nz.x = 0;
       nz.y = 0;
       nz.z = +1;
     }
     if (t1 > near) {
       near = t1;
       n = nz;
     }
     if (t2 < far) {
       far = t2;
     }
     if (near > far) {
       return new RayCollInfo(false);
     }
     if (far < 0) {
       return new RayCollInfo(false);
     }
  
     if(n.dot(r.direction)>0){
        n.mult(-1);
     }
     // Store collision info
     PVector hitPosition = new PVector(r.origin.x + near * r.direction.x, r.origin.y + near * r.direction.y, r.origin.z + near * r.direction.z);
     PVector reflectionVector = new PVector(-r.direction.x, -r.direction.y, -r.direction.z);
     RayCollInfo rayCollInfo = new RayCollInfo(reflectionVector, hitPosition, n, true, near);
  
     return rayCollInfo;

  }

};

class Instance extends RenderObj{
  
  int  index;
  PMatrix3D tMat;
  PMatrix3D invMat;
  
  Instance() {
    super( instanceType );
    index = -1; 
    tMat = new PMatrix3D();
    invMat = new PMatrix3D();
  }

  Instance( int _ind, PMatrix3D _Two ) {
    super( instanceType );
    index = _ind; 
    tMat = _Two.get();
    invMat = tMat.get(); 
    invMat.invert();
    material = namedRenderObjs.get(index).material;

  }

  RayCollInfo intersection( Ray R ) {
   PVector tgt = new PVector();
   PVector p1 = new PVector( R.origin.x, R.origin.y, R.origin.z );
   float[] p2 = new float[4]; 
   p2[0] = R.direction.x; 
   p2[1] = R.direction.y; 
   p2[2] = R.direction.z; 
   p2[3] = 0;
   float[] tgt2 = new float[4];
   invMat.mult( p1, tgt ); 
   invMat.mult( p2, tgt2 );
   
   PVector P2 = new PVector(tgt.x,tgt.y,tgt.z);
   PVector V2 = new PVector(tgt2[0], tgt2[1], tgt2[2]);
   
   //ray newR = Minv*a + t.Minv*b
          
   Ray ray = new Ray(P2,V2); 
   
   RayCollInfo rCInfo= namedRenderObjs.get(index).intersection(ray);
   if( rCInfo.isHit == true ) {

       PMatrix3D inv1 = invMat.get(); 
       inv1.transpose();
       PVector p3 = new PVector( R.origin.x + R.direction.x*rCInfo.rootVal, R.origin.y + R.direction.y*rCInfo.rootVal, R.origin.z + R.direction.z*rCInfo.rootVal );
       rCInfo.hitVec = new PVector(p3.x, p3.y, p3.z);
       
       PVector n4 = new PVector( rCInfo.normal.x, rCInfo.normal.y, rCInfo.normal.z );
       PVector tgt4 = new PVector();
       //newNormal = Transpose(Minv)*normal
       inv1.mult(n4, tgt4);
       rCInfo.normal.x = tgt4.x; 
       rCInfo.normal.y = tgt4.y; 
       rCInfo.normal.z = tgt4.z; 
   }
    
   return rCInfo;
  }

  void cloneData( Instance instance ) {
    index = instance.index;
    tMat = instance.tMat;
    invMat = instance.invMat;
    material = instance.material;
  }

}  


class List extends RenderObj {
 
  int listSize;
  ArrayList<RenderObj> listObjects;
  
  
  List() {
    super(listType);
    boundingBox = new Box();
    listSize = 0;
    listObjects = new ArrayList<RenderObj>();
  }
  
  void cloneData( List list ) {
    listSize = 0;
    for( int i = 0; i < listSize; ++i ) {
      if( list.listObjects.get(i).getPrimitiveType() == triangleType ) { 
        addToList((Triangle) list.listObjects.get(i) ); 
      }      
      //Add spheres and other types too
    }
    
    material = list.material;

  }

  void addToList(RenderObj renderObj) {

      if( renderObj.getPrimitiveType() == sphereType ) {
        listObjects.add((Sphere)renderObj);        
      } 
      else if(renderObj.getPrimitiveType() == triangleType ) {
        listObjects.add((Triangle)renderObj);        
      } 
      else if(renderObj.getPrimitiveType() == instanceType ) {
        listObjects.add((Instance)renderObj);        
      } 
      else if(renderObj.getPrimitiveType() == boxType ) {
        listObjects.add((Box)renderObj);        
      } 
      else if(renderObj.getPrimitiveType() == listType ) {
        listObjects.add((List)renderObj);           
      }    
    listSize++;
  }
  
  int getSize(){
    return listSize; 
  }

  boolean calcBoundingBox() {
    
    boundingBox.minPt.x = 1000; 
    boundingBox.minPt.y = 1000; 
    boundingBox.minPt.z = 1000;
    boundingBox.maxPt.x = -1000; 
    boundingBox.maxPt.y = -1000; 
    boundingBox.maxPt.z = -1000; 
        
    float[] b = new float[6];
    
    // Loop through all bounding boxes of the list objects and calculate the bounding box for this list as a whole
    for( int i = 0; i < listSize; i++ ) {
       listObjects.get(i).calcBoundaryBox();
       b = listObjects.get(i).getBoundaryBoxDimensions();
       if (boundingBox.minPt.x > b[0]) {
           boundingBox.minPt.x = b[0];
       }
       if (boundingBox.minPt.y > b[1]) {
           boundingBox.minPt.y = b[1];
       }
       if (boundingBox.minPt.z > b[2]) {
           boundingBox.minPt.z = b[2];
       }
       if (boundingBox.maxPt.x > b[3]) {
           boundingBox.maxPt.x = b[3];
       }
       if (boundingBox.maxPt.y > b[4]) {
           boundingBox.maxPt.y = b[4];
       }
       if (boundingBox.maxPt.z > b[5]) {
           boundingBox.maxPt.z = b[5];
       }
    } 
    return true;
  }


    /**< hit function */
  RayCollInfo intersection(Ray R) {
    RayCollInfo rayCollInfo = new RayCollInfo(false);
    RayCollInfo boundingBoxHit = boundingBox.intersection(R);
    
    if( boundingBoxHit.isHit ) {

      double minDist = 1000;
      int minInd = -1;
      boolean got = false;

      for( int i = 0; i < listSize; i++ ) {
         RayCollInfo objectHit = ( (Triangle) listObjects.get(i)).intersection(R);
         if( objectHit.isHit ) {
            got = true;
            if( objectHit.rootVal < minDist ) {
                minDist = objectHit.rootVal;
                minInd = i;
                rayCollInfo = objectHit;
            } 
        }
        
      }
      
      if( got ) {
          material = listObjects.get(minInd).material;   
      }
      return rayCollInfo;
    }
    else{
      return new RayCollInfo(false); 
    }

  }
  
  
};



class BVH extends RenderObj{

  public int axis;
  public RenderObj leftObj;
  public RenderObj rightObj;
  
  BVH( RenderObj[] objects, int a ) {
    super(bvhType);
    boundingBox = new Box();
    axis = a;
    leftObj = new RenderObj();
    rightObj = new RenderObj();
    calcBoundingBox(objects);

    //Currently coded only for triangles. 
    if( objects.length == 1 ) {
        leftObj = (Triangle) objects[0];
        material = leftObj.material; 
        //mAmb = left.mAmb;
        //mDiff = left.mDiff;
           
    } else if( objects.length == 2 ) {
        leftObj = (Triangle) objects[0];
        rightObj = (Triangle) objects [1];
    } else {       
        Triangle[][] partitions = partitionAtAxis(objects); 
        if( partitions[0].length > 0 ) {
            leftObj = new BVH( partitions[0], (axis + 1) % 3 );
        }  
    
        if( partitions[1].length > 0 ) { 
            rightObj = new BVH( partitions[1], (axis + 1) %3 );       
        }
    }
    
  }
  
  void copyData( BVH bvh ) { print("BVH Should not come here");}
  
  boolean calcBoundingBox(RenderObj[] objects) {

    boundingBox.minPt.x = 1000; 
    boundingBox.minPt.y = 1000; 
    boundingBox.minPt.z = 1000;
    boundingBox.maxPt.x = -1000; 
    boundingBox.maxPt.y = -1000; 
    boundingBox.maxPt.z = -1000; 
        
    float[] b = new float[6];
    
    for( int i = 0; i < objects.length; i++ ) {
       b = objects[i].getBoundaryBoxDimensions();
       if (boundingBox.minPt.x > b[0]) {
           boundingBox.minPt.x = b[0];
       }
       if (boundingBox.minPt.y > b[1]) {
           boundingBox.minPt.y = b[1];
       }
       if (boundingBox.minPt.z > b[2]) {
           boundingBox.minPt.z = b[2];
       }
       if (boundingBox.maxPt.x > b[3]) {
           boundingBox.maxPt.x = b[3];
       }
       if (boundingBox.maxPt.y > b[4]) {
           boundingBox.maxPt.y = b[4];
       }
       if (boundingBox.maxPt.z > b[5]) {
           boundingBox.maxPt.z = b[5];
       }
    }  
    
    return true;

  }
  
  Triangle[][] partitionAtAxis( RenderObj[] objects ) {
    Triangle[][] parts = new Triangle[2][];
    // Find m: Middle point in axis
    float m = 0;
    int n = objects.length;
    if(axis == 0)
        m = ( boundingBox.minPt.x + boundingBox.maxPt.x ) / 2.0; 
    if(axis == 1)
        m = ( boundingBox.minPt.y + boundingBox.maxPt.y ) / 2.0; 
    if(axis == 2)
        m = ( boundingBox.minPt.z + boundingBox.maxPt.z ) / 2.0; 
        
    // Partition
    Triangle[] tleft = new Triangle[n];
    Triangle[] tright = new Triangle[n];    
    int counter_left = 0;
    int counter_right = 0;
    
    //Currently works only for triangle 
    float p = 0;
    for( int i = 0; i < n; ++i ) {
        if(axis == 0)
            p = ( objects[i].boundingBox.maxPt.x + objects[i].boundingBox.minPt.x ) / 2.0;
        if(axis == 1)
            p = ( objects[i].boundingBox.maxPt.y + objects[i].boundingBox.minPt.y ) / 2.0;
        if(axis == 2)
            p = ( objects[i].boundingBox.maxPt.z + objects[i].boundingBox.minPt.z ) / 2.0;
        if( p < m ) { 
            tleft[counter_left] = (Triangle) objects[i];
            counter_left++; 
        } else {
            tright[counter_right] = (Triangle) objects[i]; 
            counter_right++;
        }    
    }
    
    // Now put the elements into pleft and pright
    Triangle[] pleft = new Triangle[counter_left];
    Triangle[] pright = new Triangle[counter_right];    
    for( int i = 0; i < counter_left; ++i ) {
      pleft[i] = (Triangle) tleft[i];
    }

    for( int i = 0; i < counter_right; ++i ) {
      pright[i] = (Triangle) tright[i];
    }
   
   parts[0] = pleft;
   parts[1] = pright; 
  
    return parts;
  }


  RayCollInfo intersection( ray R) { 
    
    RayCollInfo boundingBox.intersection(R);
    if( bb.hit( _R, _rec ) ) {
      hitRecord lrec = new hitRecord();
      hitRecord rrec = new hitRecord();
      boolean left_hit, right_hit;
      
      left_hit = left.hit( _R, lrec );
      right_hit = right.hit( _R, rrec );
      if( left_hit && right_hit ) {
        if( lrec.dist < rrec.dist ) {
          _rec.copyData(lrec);
        } else {
          _rec.copyData(rrec);
        }        
        mAmb[0] = _rec.amb[0]; mAmb[1] = _rec.amb[1]; mAmb[2] = _rec.amb[2];
        mDiff[0] = _rec.diff[0]; mDiff[1] = _rec.diff[1]; mDiff[2] = _rec.diff[2];
        return true;
      } else if( left_hit ) {
        _rec.copyData(lrec);
        mAmb[0] = _rec.amb[0]; mAmb[1] = _rec.amb[1]; mAmb[2] = _rec.amb[2];
        mDiff[0] = _rec.diff[0]; mDiff[1] = _rec.diff[1]; mDiff[2] = _rec.diff[2];
        return true;
      } else if( right_hit ) {
        _rec.copyData(rrec);
        mAmb[0] = _rec.amb[0]; mAmb[1] = _rec.amb[1]; mAmb[2] = _rec.amb[2];
        mDiff[0] = _rec.diff[0]; mDiff[1] = _rec.diff[1]; mDiff[2] = _rec.diff[2];
        return true;
      } else {
        return false;
      }
      
      
    } 
    //No intersection
    else {
      return false;
    }
    
    
  }
  
  
  void printInfo() {
  }

  
  
};  