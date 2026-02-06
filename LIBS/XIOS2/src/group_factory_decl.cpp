#include "group_factory_impl.hpp"
#include "node_type.hpp"

namespace xios
{
# define  macro(U) \
  template void CGroupFactory::AddGroup<U>(boost::shared_ptr<U> pgroup,boost::shared_ptr<U> cgroup); \
  template void CGroupFactory::AddChild<U>(boost::shared_ptr<U> group, boost::shared_ptr<U::RelChild> child); \
  template boost::shared_ptr<U>  CGroupFactory::GetGroup<U>(boost::shared_ptr<U> group, const StdString & id); \
  template boost::shared_ptr<U::RelChild> CGroupFactory::GetChild<U>(boost::shared_ptr<U> group, const StdString & id); \
  template int CGroupFactory::GetGroupNum<U>(boost::shared_ptr<U> group); \
  template int CGroupFactory::GetGroupIdNum<U>(boost::shared_ptr<U> group); \
  template int CGroupFactory::GetChildNum<U>(boost::shared_ptr<U> group); \
  template int CGroupFactory::GetChildIdNum<U>(boost::shared_ptr<U> group); \
  template bool CGroupFactory::HasGroup<U>(boost::shared_ptr<U> group, const StdString & id); \
  template bool CGroupFactory::HasChild<U>(boost::shared_ptr<U> group, const StdString & id); \
  template boost::shared_ptr<U> CGroupFactory::CreateGroup<U>(boost::shared_ptr<U> group, const StdString & id ); \
  template boost::shared_ptr<U::RelChild>  CGroupFactory::CreateChild<U>(boost::shared_ptr<U> group, const StdString & id);

  macro(CFieldGroup)
  macro(CFileGroup)
  macro(CGridGroup)
  macro(CAxisGroup)
  macro(CDomainGroup)
  macro(CContextGroup)
  macro(CVariableGroup)
  macro(CInverseAxisGroup)
  macro(CZoomAxisGroup)
  macro(CInterpolateAxisGroup)
  macro(CZoomDomainGroup)
  macro(CInterpolateDomainGroup)
  macro(CGenerateRectilinearDomainGroup)
  macro(CScalarGroup)
  macro(CReduceAxisToScalarGroup)
  macro(CReduceDomainToAxisGroup)
  macro(CExtractDomainToAxisGroup)
  macro(CComputeConnectivityDomainGroup)
  macro(CExpandDomainGroup)
  macro(CExtractAxisToScalarGroup)
  macro(CReduceDomainToScalarGroup)
}
