using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Rendering.Pipline
{
    [Serializable,CreateAssetMenu(fileName = "Render Resource",menuName = "Rendering/Render Resources")]
    public class RenderResources : ScriptableObject
    {
        [SerializeField] private Shader[] m_PostProcess;
        [SerializeField] private Shader[] m_IncludeShaders;
        [SerializeField] private ComputeShader[] m_ComputeShader;

        private static RenderResources Instance;

        public RenderResources()
        {
            Instance = this;
        }

        public static Shader FindPostProcess(string _name)
        {
            var shader = Array.Find(Instance.m_PostProcess,p => p != null && p.name == _name);
            if (shader == null)
                Debug.LogWarning($"Invalid Post Process Shader:{_name} Found!");
            return shader;
        }
        
        public static Shader FindInclude(string _name)
        {
            var shader = Array.Find(Instance.m_IncludeShaders,p => p != null && p.name == _name);
            if (shader == null)
                Debug.LogWarning($"Invalid include Shader:{_name} Found!");
            return shader;
        }
        
        public static ComputeShader FindComputeShader(string _name)
        {
            var shader = Array.Find(Instance.m_ComputeShader,p => p != null && p.name == _name);
            if (shader == null)
                Debug.LogWarning($"Invalid Compute Shader:{_name} Found!");
            return shader;
        }
        
    }
}
