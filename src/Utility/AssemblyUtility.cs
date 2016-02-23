using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;

namespace Utility
{
    public static class AssemblyUtility
    {
        /// <summary>
        /// Uses DynamoInstallDetective.dll to search the registry for Dynamo Installations.
        /// </summary>
        /// <returns>Returns the full path to the Dynamo Core.</returns>
        public static string DynamoCoreDirectory()
        {
            var dynamoVersion = Assembly.GetExecutingAssembly().GetName().Version;

            var dynamoProducts = DynamoInstallDetective.Utilities.FindDynamoInstallations("");
            foreach (KeyValuePair<string, Tuple<int, int, int, int>> prod in dynamoProducts)
            {
                var installedVersion = (prod.Value.Item1.ToString() + "." + prod.Value.Item2.ToString());

                if (installedVersion == dynamoVersion.ToString(2))
                {
                    return prod.Key;
                }
            }

            return string.Empty;
        }

        /// <summary>
        /// Uses Assembly reference to obtain the Revit folder.
        /// </summary>
        /// <returns>Returns the full path to Dynamo Revit folder.</returns>
        public static string AssemblyDirectory()
        {
            var assemblyLocation = Assembly.GetExecutingAssembly().Location;
            var assemblyDirectory = Path.GetDirectoryName(assemblyLocation);
            return assemblyDirectory;
        }

        /// <summary>
        /// Uses Assembly reference to obtain the Revit folder.
        /// </summary>
        /// <returns>Returns the full path to DynamoRevitDS.dll.</returns>
        public static string DynamoRevitPath()
        {
            return Path.Combine(AssemblyDirectory(), "DynamoRevitDS.dll");
        }
    }
}
