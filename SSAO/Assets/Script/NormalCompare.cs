using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class NormalCompare : MonoBehaviour
{
    private Camera cam { get {return GetComponent<Camera>();}}
    public bool isDeffered = false;
    void Awake()
    {
        cam.depthTextureMode |= DepthTextureMode.DepthNormals;
        // 默认前向渲染
        isDeffered = false;
        cam.renderingPath = RenderingPath.Forward;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(isDeffered){
            cam.renderingPath = RenderingPath.DeferredShading;
            Graphics.Blit(null,destination,new Material(Shader.Find("SSAO/NormalCompare")),1);
        }
        else{
            cam.renderingPath = RenderingPath.Forward;
            Graphics.Blit(null,destination,new Material(Shader.Find("SSAO/NormalCompare")),0);
        }
    }
}
