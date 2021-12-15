/*
 * Copyright (c) 2020-2021 Arm Limited. All rights reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include "ProjMgrKernel.h"
#include "ProjMgrCallback.h"
#include "ProjMgrXmlParser.h"

#include "RteFsUtils.h"
#include "RteKernel.h"

#include <iostream>

using namespace std;

// Singleton kernel object
static unique_ptr<ProjMgrKernel> theProjMgrKernel = 0;

ProjMgrKernel::ProjMgrKernel() {
  m_callback = make_unique<ProjMgrCallback>();
  SetRteCallback(m_callback.get());
}

ProjMgrKernel::~ProjMgrKernel() {
  if (m_callback) {
    m_callback.reset();
  }
}

ProjMgrKernel *ProjMgrKernel::Get() {
  if (!theProjMgrKernel) {
    theProjMgrKernel = make_unique<ProjMgrKernel>();
  }
  return theProjMgrKernel.get();
}

void ProjMgrKernel::Destroy() {
  if (theProjMgrKernel) {
    theProjMgrKernel.reset();
  }
}

XMLTree* ProjMgrKernel::CreateXmlTree() const
{
  // RteKernel has the pointer ownership
  unique_ptr<ProjMgrXmlParser> xmlParser = make_unique<ProjMgrXmlParser>();
  return xmlParser.release();
}

bool ProjMgrKernel::GetInstalledPacks(list<RtePackage*>& packs) {
  list<string> pdscFiles;
  RteFsUtils::GetPackageDescriptionFiles(pdscFiles, theProjMgrKernel->GetCmsisPackRoot(), 3);
  for (const auto& pdscFile : pdscFiles) {
    RtePackage* pack = theProjMgrKernel->LoadPack(pdscFile);
    if (!pack) {
      return false;
    }
    packs.push_back(pack);
  }
  RteGlobalModel* globalModel = theProjMgrKernel->GetGlobalModel();
  if (!globalModel) {
    return false;
  }
  globalModel->InsertPacks(packs);
  return true;
}
