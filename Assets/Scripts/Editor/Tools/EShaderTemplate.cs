using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace UnityEditor.Extensions
{
    internal static class EShaderTemplate
    {
        private const string folder = "Assets/Shaders/Templates/";

        [MenuItem(itemName: "Assets/Create/Shader/HLSLShader")]
        static void CreateHLSLShaderTemlates()
        {
            ProjectWindowUtil.CreateScriptAssetFromTemplateFile(folder+"HLSLTemplate.shader.txt","NewHLSLShader.shader");
        }

        [MenuItem(itemName: "Assets/Create/Shader/HLSLInclude")]
        static void CreateHLSLIncludeTemplates()
        {
            ProjectWindowUtil.CreateScriptAssetFromTemplateFile(folder+"HLSLIncludeTemplate.hlsl.txt","NewHLSLInclude.hlsl");
        }
    }
}
