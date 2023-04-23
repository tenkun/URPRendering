using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Rendering.Pipline
{
    public class SDP_GlobalParameters : ScriptableRenderPass
    {
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var camera = renderingData.cameraData.camera;

            float aspect = camera.aspect;
            float near = camera.nearClipPlane;
            Vector3 orgiPos = near * camera.transform.forward;
            Vector3 toRight;
            Vector3 toTop;
            float halfHeight;
            if (camera.orthographic)
            {
                Shader.SetGlobalVector(KCameraParametersID.kOrthoDirection,camera.transform.forward);
                halfHeight = camera.orthographicSize;
                toRight = halfHeight * camera.transform.right * aspect;
                toTop = halfHeight * camera.transform.up;
                
                Shader.SetGlobalVector(KCameraParametersID.kOrthoBL,orgiPos-toRight-toTop);
                Shader.SetGlobalVector(KCameraParametersID.kOrthoBR,orgiPos+toRight-toTop);
                Shader.SetGlobalVector(KCameraParametersID.kOrthoTL,orgiPos-toRight+toTop);
                Shader.SetGlobalVector(KCameraParametersID.kOrthoTR,orgiPos+toRight+toTop);
            }
            else
            {
                halfHeight = near * Mathf.Tan(camera.fieldOfView * 0.5f * Mathf.Deg2Rad);
                toRight = halfHeight * camera.transform.right * aspect;
                toTop = halfHeight * camera.transform.up;
                Vector3 tl = orgiPos - toRight + toTop;
                float scale = tl.magnitude / near;
                tl.Normalize();
                tl *= scale;
                Vector3 tr = orgiPos + toRight + toTop;
                tr.Normalize();
                tr *= scale;
                Vector3 bl = orgiPos - toRight - toTop;
                bl.Normalize();
                bl *= scale;
                Vector3 br = orgiPos + toRight - toTop;
                br.Normalize();
                br *= scale;

                Shader.SetGlobalVector(KCameraParametersID.kFrustumCornersRayBL, new Vector4(bl.x,bl.y,bl.z, 0));
                Shader.SetGlobalVector(KCameraParametersID.kFrustumCornersRayBR,new Vector4(br.x,br.y,br.z,0));
                Shader.SetGlobalVector(KCameraParametersID.kFrustumCornersRayTL,new Vector4(tl.x,tl.y,tl.z,0));
                Shader.SetGlobalVector(KCameraParametersID.kFrustumCornersRayTR,new Vector4(tr.x,tr.y,tr.z,0));
            }

            Matrix4x4 projection = GL.GetGPUProjectionMatrix(renderingData.cameraData.GetProjectionMatrix(),renderingData.cameraData.IsCameraProjectionMatrixFlipped());
            Matrix4x4 view = renderingData.cameraData.GetViewMatrix();
            Matrix4x4 vp = projection * view;

            Shader.SetGlobalMatrix(KCameraParametersID.kMatrix_VP,vp);
            Shader.SetGlobalMatrix(KCameraParametersID.kMatrix_I_VP,vp.inverse);
            Shader.SetGlobalMatrix(KCameraParametersID.kMatrixV,view);
        }
    }
}
