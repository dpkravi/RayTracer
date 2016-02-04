int firstIntersection(ArrayList<RenderObj> renderList, Ray currentRay)
{
    ArrayList<Integer> collList = new ArrayList<Integer>();
    //Create a list of all the ray object intersections for this particular ray
    for(int i = 0; i < renderList.size(); i++)
    {
        RenderObj newRenderable = renderList.get(i);
        RayCollInfo newRayCollInfo = newRenderable.intersection(currentRay);
        if(newRayCollInfo.isHit)
        {
            collList.add(i);
        }
    }
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

PVector getColor(ArrayList<Light> lights, RenderObj currentObj, RayCollInfo rayCollInfo)
{
   
    //Ambient color
    PVector finalColor = new PVector(currentObj.material.ambientCoeff.x, currentObj.material.ambientCoeff.y, currentObj.material.ambientCoeff.z);
    for(int i = 0; i < lights.size(); i++)
    {
        Light currentLight = lights.get(i);
        PVector lightVec = new PVector(currentLight.position.x - rayCollInfo.hitVec.x, currentLight.position.y - rayCollInfo.hitVec.y, currentLight.position.z - rayCollInfo.hitVec.z);
        //Diffuse color
        lightVec.normalize();
        rayCollInfo.normal.normalize();
        // (N.L)
        float NL = max(rayCollInfo.normal.dot(lightVec), 0);
        PVector diffuseShading = new PVector( currentObj.material.diffuseCoeff.x*currentLight.colour.x*NL, currentObj.material.diffuseCoeff.y*currentLight.colour.y*NL, currentObj.material.diffuseCoeff.z*currentLight.colour.z*NL);
        finalColor.x = finalColor.x + diffuseShading.x;
        finalColor.y = finalColor.y + diffuseShading.y;
        finalColor.z = finalColor.z + diffuseShading.z;
    }
    return finalColor;
}