
PVector getColor(ArrayList<Light> lights, ArrayList<RenderObj> renderList, RenderObj currentObj, RayCollInfo rayCollInfo)
{
    //Ambient color
    PVector finalColor = new PVector(currentObj.material.ambientCoeff.x, currentObj.material.ambientCoeff.y, currentObj.material.ambientCoeff.z);
    for(int i = 0; i < lights.size(); i++)
    {
        Light currentLight = lights.get(i);
        Ray shadowRay = new Ray();
        if(currentLight.lightType == 1){
            shadowRay = getPointLightShadowRay(lights.get(i), rayCollInfo.hitVec);
        }
        if(currentLight.lightType == 2){
            shadowRay = getDiskLightShadowRay(lights.get(i), rayCollInfo.hitVec);
        } 

        shadows = false;
        PVector lightVec = new PVector(currentLight.position.x - rayCollInfo.hitVec.x, currentLight.position.y - rayCollInfo.hitVec.y, currentLight.position.z - rayCollInfo.hitVec.z);
        for( int j = 0; j< renderList.size(); j++){
          
          float lightValue = lightVec.mag();

          RayCollInfo shadowIntersection = renderList.get(j).intersection(shadowRay);
          shadowIntersection.objIndex = j;
          
          //Had a problem with shadows being generated by the same object so ignoring the objects that are same as shadow ray origin
          //if(shadowIntersection.isHit && (shadowIntersection.rootVal <= lightValue) && (shadowIntersection.objIndex != rayCollInfo.objIndex))
          
          //Removed above commented condition (shadowIntersection.objIndex != rayCollInfo.objIndex)
          //Because of that condition the bunny was not casting a shadow on itself.
          if(shadowIntersection.isHit && (shadowIntersection.rootVal <= lightValue))
          {
             shadows = true;
             j = renderList.size();
          }
        }
        if(shadows == false){
          //Diffuse color
          lightVec.normalize();
          rayCollInfo.normal.normalize();
          // (N.L)
          float NL = max(rayCollInfo.normal.dot(shadowRay.direction), 0);
          PVector diffuseShading = new PVector( currentObj.material.diffuseCoeff.x*currentLight.colour.x*NL, currentObj.material.diffuseCoeff.y*currentLight.colour.y*NL, currentObj.material.diffuseCoeff.z*currentLight.colour.z*NL);
          finalColor.x = finalColor.x + diffuseShading.x;
          finalColor.y = finalColor.y + diffuseShading.y;
          finalColor.z = finalColor.z + diffuseShading.z;
        }
    }
    return finalColor;
}
   
Ray getPointLightShadowRay(Light light, PVector hitVec){
  
    PVector normal = createVec(hitVec, light.position).normalize();
    PVector pos = new PVector(hitVec.x+0.0002*normal.x,hitVec.y+0.0002*normal.y,hitVec.z+0.0002*normal.z);
    Ray R = new Ray(pos, normal);
    return R;
}

Ray getDiskLightShadowRay(Light light, PVector hitVec){
  
    // This works only when the normal is (1,0,0)
     PVector P = new PVector(0,0,0);
     float dr = sqrt((float)Math.random());
     float dt = 2*3.14157*(float)Math.random();
     P.x = light.position.x;
     P.y = light.position.y + light.radius*dr*cos(dt);
     P.z = light.position.z + light.radius*dr*sin(dt);     
     
     PVector normal = createVec(hitVec, P).normalize();

     PVector pos = new PVector(hitVec.x+0.0002*normal.x,hitVec.y+0.0002*normal.y,hitVec.z+0.0002*normal.z);
     Ray R = new Ray(pos, normal);
     return R;

}

boolean isInShadow(Ray shadowRay){
    for(int i = 0; i < renderList.size(); i++) {
       if(isIntersect(shadowRay, i))
       {
           return true; 
       }
    }
    return false;
}

boolean isIntersect( Ray shadowRay, int i ) {
    RayCollInfo shadowIntersection = renderList.get(i).intersection(shadowRay);
    if(shadowIntersection.isHit && shadowIntersection.rootVal <= lightValue)
    {
        return true;
    }
    else
    {
        return false;
    }
}
 
Ray getRayAtPixel(int u, int v, boolean isCenter){
  
    Ray R = new Ray();
    float un,vn;
    //If single ray to center ( when 1 ray per pixel)
    if(isCenter){
        un = 0.5; vn = 0.5;
    } else {    // When multiple rays per pixel
        un = (float)Math.random();
        vn = (float)Math.random();
    }
    
    PVector origin = new PVector(0,0,0);
    PVector target = new PVector(camLeft + ((camRight-camLeft)*(v+vn)/width), camBottom+ ((camTop-camBottom)*(u+un)/height), -1.0);
    PVector direction = new PVector(target.x - origin.x, target.y - origin.y, -1.0); 
    //Normalizing the direction
    direction.normalize();
    R.origin = origin;
    R.direction = direction;
    return R;
}

PVector computeColor(ArrayList<RenderObj> renderList, Ray currentRay){
  
    Ray newRay;
    
    if(renderList.size() > 0)
    {  

      if(setLens){

         //Our default lens / eye location is at origin
         PVector eyeLoc = new PVector(0,0,0);
         //Find intersection of the ray with the focal plane
         float inter = (-focalDistance - currentRay.origin.z)/(currentRay.direction.z);
         PVector FocalPoint = new PVector(currentRay.origin.x+inter*currentRay.direction.x,currentRay.origin.y+inter*currentRay.direction.y,currentRay.origin.z+inter*currentRay.direction.z);
          
         //Get a random point around they eye(lens)
         PVector eye = new PVector(0,0,0);
         float dr = sqrt((float)Math.random());
         float dt = 2*3.14157*(float)Math.random();
         eye.x = eyeLoc.x + lensRadius*dr*cos(dt);
         eye.y = eyeLoc.y + lensRadius*dr*sin(dt);
         eye.z = eyeLoc.z;
          
         //get ray between random lens point and focal point
         PVector lf = createVec(eye,FocalPoint);
          
         newRay = new Ray(eye, lf); 

      }
      else{

        newRay = currentRay;
      }

      RenderObj currentRenderObj = null;
      RayCollInfo rayCollInfo = firstIntersection(newRay);

      if(rayCollInfo.objIndex!=-1){
         currentRenderObj = renderList.get(rayCollInfo.objIndex);
      }
      if(rayCollInfo.isHit)
       {     

           return(getColor(lights,renderList,currentRenderObj, rayCollInfo));
       }
       else
       {       
           return(backgroundColor);
       }
    }
    return null;
}



RayCollInfo firstIntersection(Ray R ) {
   
     RayCollInfo rayCollInfo = new RayCollInfo(false);
  
     rayCollInfo.objIndex = -1; 
     smallestDist = 1000; 
     closestIndex = -1; 
     closestNormal = new PVector(0,0,0);
  
     for( int i = 0; i < renderList.size(); i++ ) {
       intersect(R, i);
     }
     
     if( closestIndex != -1 ) { 
       rayCollInfo.objIndex = closestIndex; 
       rayCollInfo.hitVec = closestHit; 
       rayCollInfo.normal = closestNormal.normalize();
       rayCollInfo.isHit = true;
     }
       
     return rayCollInfo;
 }
 
 //Looping through all objects and storing the values for the closest intersection
 boolean intersect( Ray R, int i ) {

    RayCollInfo rec;     
    rec = renderList.get(i).intersection(R);

    if( rec.isHit == true ) {
       if( rec.rootVal < smallestDist ) { 
         smallestDist = rec.rootVal; 
         closestIndex = i; 
         closestHit = rec.hitVec; 
         closestNormal = rec.normal;
       } 
       return true;
    }
    return false;
}