#!/bin/bash
#This library provides the equivalent set of functions as its powershell counterpart but for a linux based environment.
#There are some differences, namely around the use of package managers and the installation of binary files

#Parse named parameters
function Parse-NamedParameters() {
  # Define the default values for optional parameters
  local container="repository"
  local buildScriptsFolder="/tmp/BuildScripts"
  local runLocally=false

  # Define the hash to store the parameters
  declare -A parameters

  # Parse named parameters
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --storageAccount)
        parameters["storageAccount"]="$2"
        shift
        shift
        ;;
      --sasToken)
        parameters["sasToken"]="$2"
        shift
        shift
        ;;
      --container)
        container="$2"
        shift
        shift
        ;;
      --buildScriptsFolder)
        buildScriptsFolder="$2"
        shift
        shift
        ;;
      --runLocally)
        runLocally=true
        shift
        ;;
      *)
        echo "Unknown parameter: $1"
        exit 1
        ;;
    esac
  done

  # Validate mandatory parameters
  if [[ -z "${parameters["storageAccount"]}" ]]; then
    echo "storageAccount parameter is mandatory"
    exit 1
  fi

  if [[ -z "${parameters["sasToken"]}" ]]; then
    echo "sasToken parameter is mandatory"
    exit 1
  fi

  # Set parameter values in the hash
  parameters["container"]="$container"
  parameters["buildScriptsFolder"]="$buildScriptsFolder"
  parameters["runLocally"]="$runLocally"

  # Return the hash of parameters
  echo "${parameters[@]}"
}

#Validate URL
#Function that takes a URL and validates to make sure that it is both valid and exists
function Check-ValidURL() {
  local url="$1"

  if [[ ! "$url" =~ ^(http|https):// ]]; then
      return 1
  fi

  # Check if curl is installed and if not install it
  if ! command -v curl > /dev/null 2>&1; then
      #curl is not installed, installing
      if command -v apt > /dev/null 2>&1; then
          sudo apt update && sudo apt install curl -y
      elif command -v yum > /dev/null 2>&1; then
          sudo yum update && sudo yum install curl -y
      else
          #Unable to install curl, please install it manually.
          return 1
      fi
  fi

  if ! curl --head --silent --fail "$url" >/dev/null; then
      return 1
  fi

  return 0
}

#Validate that WGET is installed (and install it if not)
function Check-Install-Wget() {
    if command -v wget &>/dev/null; then
        # wget is already installed
        return 0
    fi

    if command -v apt &>/dev/null; then
        sudo apt update
        sudo apt install -y wget
    elif command -v yum &>/dev/null; then
        sudo yum update
        sudo yum install -y wget
    else
        #Unable to install wget - unsupported package manager
        return 1
    fi

    if command -v wget &>/dev/null; then
        #wget has been successfully installed
        return 0
    else
        #wget installation failed
        return 1
    fi
}


#File repo functions
function Get-RepoContext { 
    echo "TODO: Get the context of the repo"
}

function Get-FileFromRepo { 
    echo "TODO: Get a file from the repo"
}

#Install exes
function Install-DPKGFromRepo { 
    echo "TODO: Install a Debian DPKG package from the local repo"
}

#Refresh the list of packages in the repository
function Update-PackageRepo {
    if command -v apt &> /dev/null; then
        sudo apt-get update
    elif command -v yum &> /dev/null; then
        sudo yum makecache
    else
        echo "Neither apt nor yum found, package repository cannot be refreshed."
        return 1
    fi

    return 0
}

#Do an "upgrade" of the packages installed to bring them to the latest verison
function Update-InstalledPackages {
  if command -v apt >/dev/null 2>&1; then
    sudo apt update
    sudo apt upgrade -y
  elif command -v yum >/dev/null 2>&1; then
    sudo yum update -y
  else
    echo "Error: Neither apt nor yum package manager found."
    return 1
  fi
}

#Install a DPKG package from a provided URL
#Will validate and check the existance of the URL
function Install-DPKGFromUrl { 
    local url="$1"
    local buildScriptFolder="$2"
    local isValid=$(Check-ValidURL "$url")

    #Check if the URL is valid
    if [[ $isValid -eq 0 ]]; then
        echo "The DPKG URL is valid and exists"
    else
        echo "The DPKG URL is not valid or does not exist"
        return 1
    fi

    #Check if WGET is installed
    echo "Checking if WGET is installed"
    local isWget=$(Check-Install-Wget)
    
    if [[ $isWget -ne 0 ]]; then
        echo "FATAL: WGET could not be installed"
        return 1
    fi

    #Install the DPKG package from URL
    echo "Installing DPKG from URL: $url"

    filename=$(basename $url)

    wget $url -O "$buildScriptFolder/$filename"
    sudo dpkg -i "$buildScriptFolder/$filename"

    #Check if it has installed correctly
    dpkg-query -W -f='${Status}' "${filename%.*}" 2>/dev/null | grep -q "^install ok installed$"
    
    if [ $? -eq 0 ]; then
        echo "$filename is installed"
        return 0
    else
        echo "$filename is not installed"
        return 1
    fi
}

function Install-RPMFromRepo { 
    echo "TODO: Install an RPM package from the local repo"
}

#Python functions
function Get-PythonLocation { 
    echo "TODO: Return the current location of python"
}
function Install-PythonPip { 
    echo "TODO: Install pythin pip (and python if not already installed)"
}
function Install-PythonPipList { 
    echo "TODO: Take a text file and install all the python modules on the list"
}

#Install a package from either apt or yum
function Install-Package {
    local pkg="$1"
    local pm
    local package_list=()

    if command -v apt >/dev/null 2>&1; then
        pm="apt"
    elif command -v yum >/dev/null 2>&1; then
        pm="yum"
    else
        echo "Unable to determine package manager. Aborting."
        return 1
    fi

    echo "Using package manager: $pm"

    # Split the space-separated packages string into an array
    read -ra package_list <<< "$pkg"

    if [[ "$pm" == "apt" ]]; then
        echo "Installing ${package_list[@]}"
        sudo apt-get install -y "${package_list[@]}"
    elif [[ "$pm" == "yum" ]]; then
        sudo yum -y install "${package_list[@]}"
    fi
}

function Install-PackageListFromRepo() {
    local package_file="$1"

    #TODO: Pull from repo

    # Check that the package file exists and is readable
    if [[ ! -r "$package_file" ]]; then
        echo "Error: package file $package_file not found or not readable."
        return 1
    fi

    # Install each package listed in the file
    while read package; do
        if [[ -n "$package" ]]; then
            install_package "$package"
        fi
    done < "$package_file"
}

#Take a direct url (e.g. a path to a remote script) and push it to bash and run it
function Install-FromCurl-BashScript() {
  local url="$1"
  local isValid=$(Check-ValidURL "$url")

  #Check if the URL is valid
  if [[ $isValid -eq 0 ]]; then
      echo "The URL is valid and exists"
  else
      echo "The URL is not valid or does not exist"
      return 1
  fi

  echo "Getting: $url and piping into Bash"
  curl -sL $url | sudo bash
}


#Take a direct url of a remote file or folder and download it changing the path to be the required permission
function Install-FromCurl-OutputFile() {
  local url="$1"
  local dlpath="$2"
  local permission="$3"
  local isValid=$(Check-ValidURL "$url")

  #Check if the URL is valid
  if [[ $isValid -eq 0 ]]; then
      echo "The URL is valid and exists"
  else
      echo "The URL is not valid or does not exist"
      return 1
  fi

  echo "Getting: $url and piping into Bash"
  curl -Lo $dlpath $url
  eval "sudo chmod ${permission} $dlpath"
}

#SoftwareBuild
function Build-Software { 
    echo "TODO: Build and install from source.  Will install dev tools if required"
}