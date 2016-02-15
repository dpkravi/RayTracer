int firstIntersection(ArrayList<RenderObj> renderList, Ray currentRay)
{

    ArrayList<Integer> collList = new ArrayList<Integer>();
    //Create a list of all the ray object intersections for this particular ray
    if(test1){
      println(renderList.size());
      test1 = false;
    }
    for(int i = 0; i < renderList.size(); i++)
    {
        RenderObj newRenderable = renderList.get(i);
        RayCollInfo newRayCollInfo = newRenderable.intersection(currentRay);
        if(newRayCollInfo.isHit)
        {
            collList.add(i);
        }
    }
    //if(collList.size() == 0)
    //  println("worstu");
    if(collList.size() > 0)
    {
        RenderObj closestObject = renderList.get(collList.get(0));
        RayCollInfo rayCollInfo = closestObject.intersection(currentRay);
        int retIndex = collList.get(0);
        //Compare the root values and the lowest value gives the first intersection
        for(int k = 1; k < collList.size(); k++)
        {
            RenderObj newRenderObj =  renderList.get(collList.get(k));
            RayCollInfo newRayCollInfo = newRenderObj.intersection(currentRay);
            if(newRayCollInfo.rootVal < rayCollInfo.rootVal)
            {
                closestObject = newRenderObj;
                rayCollInfo = newRayCollInfo;
                retIndex = collList.get(k);
            }
        }
        return retIndex;
    }
    else
    {
        return -1;
    }
}

Ray getPointLightShadowRay(Light light, PVector hitVec){
  
    PVector normal = createVec(hitVec, light.position).normalize();
    PVector pos = new PVector(hitVec.x+0.02*normal.x,hitVec.y+0.02*normal.y,hitVec.z+0.02*normal.z);
    Ray R = new Ray(pos, normal);
    return R;
}

Ray getDiskLightShadowRay(Light light, PVector hitVec){
  
     // Hack to verify that it works. We know that normal is always towards X (I am being lazy here, but the
     // only hack so far is to do the randomization simpler in plane YZ - UPDATE THIS!)
     PVector P = new PVector(0,0,0);
     float dr = sqrt((float)Math.random());
     float dt = 2*3.14157*(float)Math.random();
     P.x = light.position.x;
     P.y = light.position.y + light.radius*dr*cos(dt);
     P.z = light.position.z + light.radius*dr*sin(dt);     
     
     PVector normal = createVec(hitVec, P).normalize();

     PVector pos = new PVector(hitVec.x+0.02*normal.x,hitVec.y+0.02*normal.y,hitVec.z+0.02*normal.z);
     Ray R = new Ray(pos, normal);
     
     return R;
}


boolean isInShadow(Ray shadowRay){
    for( int i = 0; i < renderList.size(); i++ ) {
       if( intersect(shadowRay, i ) == true ) { return true; }
    }
    return false;
}

boolean intersect( Ray shadowRay, int i ) {
    RayCollInfo shadowIntersection = renderList.get(i).intersection(shadowRay);
    if(shadowIntersection.isHit && shadowIntersection.rootVal <= lparam)
    {
        return true;
    }
    else{
        return false;
    }
 }

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

        PVector lightVec = new PVector(currentLight.position.x - rayCollInfo.hitVec.x, currentLight.position.y - rayCollInfo.hitVec.y, currentLight.position.z - rayCollInfo.hitVec.z);
        lparam = lightVec.mag();
        if(isInShadow(shadowRay) == false){
            lightVec.normalize();
            rayCollInfo.normal.normalize();
            // (N.L)
            float NL = abs(max(rayCollInfo.normal.dot(lightVec), 0));
            PVector diffuseShading = new PVector( currentObj.material.diffuseCoeff.x*currentLight.colour.x*NL, currentObj.material.diffuseCoeff.y*currentLight.colour.y*NL, currentObj.material.diffuseCoeff.z*currentLight.colour.z*NL);
            finalColor.x = finalColor.x + diffuseShading.x;
            finalColor.y = finalColor.y + diffuseShading.y;
            finalColor.z = finalColor.z + diffuseShading.z;
        
        }
      
        //shadows = false;
        //Light currentLight = lights.get(i);
        //PVector lightVec = new PVector(currentLight.position.x - rayCollInfo.hitVec.x, currentLight.position.y - rayCollInfo.hitVec.y, currentLight.position.z - rayCollInfo.hitVec.z);
        //for( int j = 0; j< renderList.size(); j++){
        //   PVector shadowDirection = lightVec;
        //   PVector shadowSource = new PVector(rayCollInfo.hitVec.x + shadowDirection.x*0.0001, rayCollInfo.hitVec.y + shadowDirection.y*0.0001, rayCollInfo.hitVec.z + shadowDirection.z*0.0001);
        //   float lParam = lightVec.mag();
        //   Ray shadowRay = new Ray(shadowSource, shadowDirection);
        //   RayCollInfo shadowIntersection = renderList.get(j).intersection(shadowRay);
        //   if(shadowIntersection.isHit && shadowIntersection.rootVal <= lParam)
        //   {
        //       shadows = true;
        //       j = renderList.size();
              
        //   }
        //}
        //if(shadows == false){
        //   //Diffuse color
        //   lightVec.normalize();
        //   rayCollInfo.normal.normalize();
        //   // (N.L)
        //   float NL = max(rayCollInfo.normal.dot(lightVec), 0);
        //   PVector diffuseShading = new PVector( currentObj.material.diffuseCoeff.x*currentLight.colour.x*NL, currentObj.material.diffuseCoeff.y*currentLight.colour.y*NL, currentObj.material.diffuseCoeff.z*currentLight.colour.z*NL);
        //   finalColor.x = finalColor.x + diffuseShading.x;
        //   finalColor.y = finalColor.y + diffuseShading.y;
        //   finalColor.z = finalColor.z + diffuseShading.z;
        //}
    }

    return finalColor;
}

PVector createVec(PVector pt1, PVector pt2){
    return new PVector(pt2.x-pt1.x, pt2.y-pt1.y, pt2.z-pt1.z);
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
    if(renderList.size() > 0)
    {  
      int closestObj = firstIntersection(renderList, currentRay);
      //No intersection happened
      if(closestObj == -1 )
      {
          return backgroundColor;
      }
      else
      {
           RenderObj currentRenderObj = renderList.get(closestObj);
           RayCollInfo rayCollInfo = currentRenderObj.intersection(currentRay);
           if(rayCollInfo.isHit)
           {
               return(getColor(lights,renderList,currentRenderObj, rayCollInfo));
           }
           else
           {
                return(backgroundColor);
           }
       }
    }
    return null;
}