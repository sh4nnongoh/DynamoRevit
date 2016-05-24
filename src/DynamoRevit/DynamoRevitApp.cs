using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Linq;
using System.IO;
using System.Reflection;
using System.Resources;
using System.Windows;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using Autodesk.Revit.ApplicationServices;
using Autodesk.Revit.Attributes;
using Autodesk.Revit.DB;
using Autodesk.Revit.UI;
using Autodesk.Revit.UI.Events;
using Dynamo.Applications.Properties;
using RevitServices.Elements;
using RevitServices.Persistence;
using RevitServices.Transactions;
using MessageBox = System.Windows.Forms.MessageBox;
using Dynamo.Models;
using RevitServices.EventHandler;
using System.Collections;
using System.Windows.Forms;

namespace Dynamo.Applications
{
    

    [Transaction(Autodesk.Revit.Attributes.TransactionMode.Automatic),
     Regeneration(RegenerationOption.Manual)]
    public class DynamoRevitApp : IExternalApplication
    {
        private static readonly string assemblyName = Assembly.GetExecutingAssembly().Location;
        private static ResourceManager res;
        public static ControlledApplication ControlledApplication;
        public static UIControlledApplication UIControlledApplication;
        public static List<IUpdater> Updaters = new List<IUpdater>();
        private static PushButton DynamoButton;

        public static string DynamoCorePath
        {
            get
            {
                if (string.IsNullOrEmpty(dynamopath))
                {
                    dynamopath = GetDynamoCorePath();
                }
                return dynamopath;
            }
        }

        /// <summary>
        /// Finds the Dynamo Core path by looking into registery or potentially a config file.
        /// </summary>
        /// <returns>The root folder path of Dynamo Core.</returns>
        private static string GetDynamoCorePath()
        {
            var version = Assembly.GetExecutingAssembly().GetName().Version;
            var dynamoRevitRootDirectory = Path.GetDirectoryName(Path.GetDirectoryName(assemblyName));
            var dynamoRoot = GetDynamoRoot(dynamoRevitRootDirectory);
            
            var assembly = Assembly.LoadFrom(Path.Combine(dynamoRevitRootDirectory, "DynamoInstallDetective.dll"));
            var type = assembly.GetType("DynamoInstallDetective.Utilities");

            var installationsMethod = type.GetMethod(
                "FindDynamoInstallations",
                BindingFlags.Public | BindingFlags.Static);

            if (installationsMethod == null)
            {
                throw new MissingMethodException("Method 'DynamoInstallDetective.Utilities.FindDynamoInstallations' not found");
            }

            var methodParams = new object[] { dynamoRoot };

            var installs = installationsMethod.Invoke(null, methodParams) as IEnumerable;
            if (null == installs)
                return string.Empty;

            return installs.Cast<KeyValuePair<string, Tuple<int, int, int, int>>>()
                .Where(p => p.Value.Item1 == version.Major && p.Value.Item2 == version.Minor)
                .Select(p=>p.Key)
                .LastOrDefault();
        }

        /// <summary>
        /// Gets Dynamo Root folder from the given DynamoRevit root.
        /// </summary>
        /// <param name="dynamoRevitRoot">The root folder of DynamoRevit binaries</param>
        /// <returns>The root folder path of Dynamo Core</returns>
        private static string GetDynamoRoot(string dynamoRevitRoot)
        {
            //TODO: use config file to setup Dynamo Path for debug builds.

            //When there is no config file, just replace DynamoRevit by Dynamo 
            //from the 'dynamoRevitRoot' folder.
            var parent = new DirectoryInfo(dynamoRevitRoot);
            var path =  string.Empty;
            while(null != parent && parent.Name != @"DynamoRevit")
            {
                path = Path.Combine(parent.Name, path);
                parent = Directory.GetParent(parent.FullName);
            }
            
            return parent != null ? Path.Combine(Path.GetDirectoryName(parent.FullName), @"Dynamo", path) : dynamoRevitRoot;
        }

        private static string dynamopath;
        private static readonly Queue<Action> idleActionQueue = new Queue<Action>(10);
        private static EventHandlerProxy proxy;
        
        public Result OnStartup(UIControlledApplication application)
        {
            // Revit2015+ has disabled hardware acceleration for WPF to
            // avoid issues with rendering certain elements in the Revit UI. 
            // Here we get it back, by setting the ProcessRenderMode to Default,
            // signifying that we want to use hardware rendering if it's 
            // available.

            RenderOptions.ProcessRenderMode = RenderMode.Default;

            try
            {
                if (false == TryResolveDynamoCore())
                    return Result.Failed;

                UIControlledApplication = application;
                ControlledApplication = application.ControlledApplication;

                SubscribeAssemblyEvents();
                SubscribeApplicationEvents();

                TransactionManager.SetupManager(new AutomaticTransactionStrategy());
                ElementBinder.IsEnabled = true;

                // Create new ribbon panel
                var panels = application.GetRibbonPanels();
                var ribbonPanel = panels.FirstOrDefault(p => p.Name.Contains(Resources.App_Description));
                if(null == ribbonPanel)
                    ribbonPanel = application.CreateRibbonPanel(Resources.App_Description);

                var fvi = FileVersionInfo.GetVersionInfo(assemblyName);
                var dynVersion = String.Format(Resources.App_Name, fvi.FileMajorPart, fvi.FileMinorPart);

                DynamoButton =
                    (PushButton)
                        ribbonPanel.AddItem(
                            new PushButtonData(
                                dynVersion,
                                dynVersion,
                                assemblyName,
                                "Dynamo.Applications.DynamoRevit"));

                Bitmap dynamoIcon = Resources.logo_square_32x32;

                BitmapSource bitmapSource =
                    Imaging.CreateBitmapSourceFromHBitmap(
                        dynamoIcon.GetHbitmap(),
                        IntPtr.Zero,
                        Int32Rect.Empty,
                        BitmapSizeOptions.FromEmptyOptions());

                DynamoButton.LargeImage = bitmapSource;
                DynamoButton.Image = bitmapSource;

                RegisterAdditionalUpdaters(application);

                RevitServicesUpdater.Initialize(DynamoRevitApp.Updaters);
                SubscribeDocumentChangedEvent();

                return Result.Succeeded;
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString());
                return Result.Failed;
            }
        }

        public Result OnShutdown(UIControlledApplication application)
        {
            UnsubscribeAssemblyEvents();
            UnsubscribeApplicationEvents();
            UnsubscribeDocumentChangedEvent();
            RevitServicesUpdater.DisposeInstance();

            return Result.Succeeded;
        }

        private static void OnApplicationIdle(object sender, IdlingEventArgs e)
        {
            if (!idleActionQueue.Any())
                return;

            Action pendingAction = null;
            lock (idleActionQueue)
            {
                pendingAction = idleActionQueue.Dequeue();
            }

            if (pendingAction != null)
                pendingAction();
        }


        /// <summary>
        /// Add an action to run when the application is in the idle state
        /// </summary>
        /// <param name="a"></param>
        public static void AddIdleAction(Action a)
        {
            // If we are running in test mode, invoke 
            // the action immediately.
            if (DynamoModel.IsTestMode)
            {
                a.Invoke();
            }
            else
            {
                lock (idleActionQueue)
                {
                    idleActionQueue.Enqueue(a);
                }
            }
        }

        public static EventHandlerProxy EventHandlerProxy
        {
            get { return proxy; }
        }

        // should be handled by the ModelUpdater class. But there are some
        // cases where the document modifications handled there do no catch
        // certain document interactions. Those should be registered here.
        /// <summary>
        ///     Register some document updaters. Generally, document updaters
        /// </summary>
        /// <param name="application"></param>
        private static void RegisterAdditionalUpdaters(UIControlledApplication application)
        {
            var sunUpdater = new SunPathUpdater(application.ActiveAddInId);

            if (!UpdaterRegistry.IsUpdaterRegistered(sunUpdater.GetUpdaterId()))
                UpdaterRegistry.RegisterUpdater(sunUpdater);

            var sunFilter = new ElementClassFilter(typeof(SunAndShadowSettings));
            var filterList = new List<ElementFilter> { sunFilter };
            ElementFilter filter = new LogicalOrFilter(filterList);
            UpdaterRegistry.AddTrigger(
                sunUpdater.GetUpdaterId(),
                filter,
                Element.GetChangeTypeAny());
            Updaters.Add(sunUpdater);
        }

        private void SubscribeApplicationEvents()
        {
            UIControlledApplication.Idling += OnApplicationIdle;

            proxy = new EventHandlerProxy();

            UIControlledApplication.ViewActivated += proxy.OnApplicationViewActivated;
            UIControlledApplication.ViewActivating += proxy.OnApplicationViewActivating;

            ControlledApplication.DocumentClosing += proxy.OnApplicationDocumentClosing;
            ControlledApplication.DocumentClosed += proxy.OnApplicationDocumentClosed;
            ControlledApplication.DocumentOpened += proxy.OnApplicationDocumentOpened;
        }

        private void UnsubscribeApplicationEvents()
        {
            UIControlledApplication.Idling -= OnApplicationIdle;

            UIControlledApplication.ViewActivated -= proxy.OnApplicationViewActivated;
            UIControlledApplication.ViewActivating -= proxy.OnApplicationViewActivating;

            ControlledApplication.DocumentClosing -= proxy.OnApplicationDocumentClosing;
            ControlledApplication.DocumentClosed -= proxy.OnApplicationDocumentClosed;
            ControlledApplication.DocumentOpened -= proxy.OnApplicationDocumentOpened;

            proxy = null;
        }

        private void SubscribeAssemblyEvents()
        {
            AppDomain.CurrentDomain.AssemblyResolve += ResolveAssembly;
            AppDomain.CurrentDomain.AssemblyLoad += AssemblyLoad;
        }

        private void AssemblyLoad(object sender, AssemblyLoadEventArgs args)
        {
            DynamoRevitApp.AppDomainHasMismatchedReferences(args.LoadedAssembly, new string[] { "SSONET", "SSONETUI", "RevitAPI" });
         
        }

        private void UnsubscribeAssemblyEvents()
        {
            AppDomain.CurrentDomain.AssemblyResolve -= ResolveAssembly;
            AppDomain.CurrentDomain.AssemblyLoad -= AssemblyLoad;
        }

        /// <summary>
        /// Handler to the ApplicationDomain's AssemblyResolve event.
        /// If an assembly's location cannot be resolved, an exception is
        /// thrown. Failure to resolve an assembly will leave Dynamo in 
        /// a bad state, so we should throw an exception here which gets caught 
        /// by our unhandled exception handler and presents the crash dialogue.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="args"></param>
        /// <returns></returns>
        public static Assembly ResolveAssembly(object sender, ResolveEventArgs args)
        {
            var assemblyPath = string.Empty;
            var assemblyName = new AssemblyName(args.Name).Name + ".dll";

            try
            {
                assemblyPath = Path.Combine(DynamoRevitApp.DynamoCorePath, assemblyName);
                if(File.Exists(assemblyPath))
                {
                    return Assembly.LoadFrom(assemblyPath);
                }

                var assemblyLocation = Assembly.GetExecutingAssembly().Location;
                var assemblyDirectory = Path.GetDirectoryName(assemblyLocation);

                // Try "Dynamo 0.x\Revit_20xx" folder first...
                assemblyPath = Path.Combine(assemblyDirectory, assemblyName);
                if (!File.Exists(assemblyPath))
                {
                    // If assembly cannot be found, try in "Dynamo 0.x" folder.
                    var parentDirectory = Directory.GetParent(assemblyDirectory);
                    assemblyPath = Path.Combine(parentDirectory.FullName, assemblyName);
                }

                return (File.Exists(assemblyPath) ? Assembly.LoadFrom(assemblyPath) : null);
            }
            catch (Exception ex)
            {
                throw new Exception(string.Format("The location of the assembly, {0} could not be resolved for loading.", assemblyPath), ex);
            }
        }

        /// <summary>
        /// Handler when an assembly is loaded into Revit's appdomain - we need to make sure
        /// that another addin has not loadead another version of a .dll that we require.
        /// If this happens Dynamo will most likely crash. We should alert the user they
        /// have an incompatible addin installed.
        /// TODO(potentially use an additional appdomain to work around this).
        /// </summary>
        /// <param name="assembly"></param>
        /// <param name="assemblyNamesToIgnore"></param>
        /// <returns></returns>
        public static bool AppDomainHasMismatchedReferences(Assembly assembly, String[] assemblyNamesToIgnore)
        {
            //get all assemblies that are currently loaded into the appdomain.
            var loadedAssemblies = AppDomain.CurrentDomain.GetAssemblies().Select(x => x.GetName()).ToList();
            // ignore some assemblies(revit assemblies) that we know work and have changed their version number format or do not align
            // with semantic versioning.
            loadedAssemblies.RemoveAll(x => assemblyNamesToIgnore.Contains(x.Name));
            //build dict- ignore those with duplicate names.
            var loadedAssemblyDict = loadedAssemblies.GroupBy(assm => assm.Name).ToDictionary(g => g.Key, g => g.First());

            foreach (var currentAssembly in assembly.GetReferencedAssemblies().Concat(new AssemblyName[] { assembly.GetName() }))
            {
                if (loadedAssemblyDict.ContainsKey(currentAssembly.Name))
                {
                    //if the dll is already loadead, then check that our required version is not greater than the currently loaded one.
                    var loadedAssembly = loadedAssemblyDict[currentAssembly.Name];
                    if (currentAssembly.Version.Major > loadedAssembly.Version.Major)
                    {
                        //TODO wrap in using or make a class out of this
                        var window =  new System.Windows.Forms.Form();
                        window.Icon = Icon.FromHandle(Properties.Resources.logo_square_32x32.GetHicon());
                        window.Text = "Dependency Error";
                        // no smaller than design time size
                        window.MinimumSize = new System.Drawing.Size(window.Width, window.Height);
                        window.Font = System.Drawing.SystemFonts.MessageBoxFont;
                        // no larger than screen size
                        window.MaximumSize = new System.Drawing.Size((int)System.Windows.SystemParameters.PrimaryScreenWidth, (int)System.Windows.SystemParameters.PrimaryScreenHeight);

                        window.AutoSize = true;
                        window.AutoSizeMode = AutoSizeMode.GrowAndShrink;

                        var table = new System.Windows.Forms.TableLayoutPanel();
                        table.AutoSize = true;
                        table.AutoSizeMode = AutoSizeMode.GrowAndShrink;
                
                        window.Controls.Add(table);



                        var shortMessage = new System.Windows.Forms.TextBox();
                        shortMessage.ReadOnly = true;
                        shortMessage.BorderStyle = 0;
                        shortMessage.BackColor = window.BackColor;
                        shortMessage.TabStop = false;
                        shortMessage.Multiline = true;
                        shortMessage.WordWrap = true;
                        shortMessage.Text = Properties.Resources.MismatchedAssemblyVersionShortMessage;
                        shortMessage.Width = 400;
                        SizeF MessageSize = shortMessage.CreateGraphics()
                                .MeasureString(shortMessage.Text,
                                                shortMessage.Font,
                                                shortMessage.Width,
                                                new StringFormat(0));
                        shortMessage.Height = (int)MessageSize.Height;


                        table.Controls.Add(shortMessage,0,0);

                        var okButton = new System.Windows.Forms.Button();
                        okButton.Text = "OK";
                        okButton.AutoSize = true;
                        okButton.MinimumSize = new System.Drawing.Size(100, 50);
                        okButton.DialogResult = System.Windows.Forms.DialogResult.OK;

                        table.Controls.Add(okButton,1,1);

                        var longMessage = new System.Windows.Forms.TextBox();
                        longMessage.ReadOnly = true;
                        longMessage.WordWrap = true;
                        longMessage.Text = string.Format(Resources.MismatchedAssemblyVersion, assembly.FullName, currentAssembly.FullName);
                        longMessage.Visible = false;



                        table.Controls.Add(longMessage,0,2);

                        var detailsButton = new System.Windows.Forms.Button();
                        detailsButton.AutoSize = true;
                        detailsButton.Text = "Show Details";
                        detailsButton.Click += (o, e) => { longMessage.Visible = !longMessage.Visible; };

                        table.Controls.Add(detailsButton,0,1);

                        window.ShowDialog();
                        window.Dispose();
                       // MessageBox.Show( string.Format(Resources.MismatchedAssemblyVersion ,assembly.FullName,currentAssembly.FullName));
                        return true;
                    }
                }
            }
            return false;
        }

      
        private void SubscribeDocumentChangedEvent()
        {
            ControlledApplication.DocumentChanged += RevitServicesUpdater.Instance.ApplicationDocumentChanged;
        }

        private void UnsubscribeDocumentChangedEvent()
        {
            ControlledApplication.DocumentChanged -= RevitServicesUpdater.Instance.ApplicationDocumentChanged;
        }
        
        public static bool DynamoButtonEnabled
        {
            get { return DynamoButton.Enabled; }
            set { DynamoButton.Enabled = value; }
        }

        private bool TryResolveDynamoCore()
        {
            if (string.IsNullOrEmpty(DynamoCorePath))
            {
                var fvi = FileVersionInfo.GetVersionInfo(assemblyName);

                if (MessageBoxResult.OK ==
                    System.Windows.MessageBox.Show(
                        string.Format(Resources.DynamoCoreNotFoundDialogMessage,
                            fvi.FileMajorPart, fvi.FileMinorPart, fvi.FileBuildPart),
                        Resources.DynamoCoreNotFoundDialogTitle,
                        MessageBoxButton.OKCancel,
                        MessageBoxImage.Error))
                {
                    System.Diagnostics.Process.Start("http://dynamobim.org/download/");
                }
                return false;
            }
            return true;
        }
    }
}